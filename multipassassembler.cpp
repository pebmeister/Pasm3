#include <iostream>
#include <iomanip>
#include <format>
#include <stack>
#include <sstream>

#include "opcodedict.h"
#include "multipassassembler.h"
#include "opcodeinfo.h"
#include "getmangledsymbol.h"
#include "findanonlabel.h"
#include "utilities.h"

/**
 * @file multipassassembler.cpp
 * @author Paul Baxter
*/

/**
 * @brief Maps 6502 addressing modes to their byte length.
 * @param mode Addressing mode (`RULE_TYPE`).
 * @return Instruction byte count (1 to 3).
 */
size_t MultiPassAssembler::GetInstructionSize(RULE_TYPE mode) {
    switch (mode) {
        case RULE_TYPE::Op_Implied:
        case RULE_TYPE::Op_Accumulator:
            return 1;

        case RULE_TYPE::Op_Immediate:
        case RULE_TYPE::Op_ZeroPage:
        case RULE_TYPE::Op_ZeroPageX:
        case RULE_TYPE::Op_ZeroPageY:
        case RULE_TYPE::Op_IndirectX:
        case RULE_TYPE::Op_IndirectY:
        case RULE_TYPE::Op_Relative:
            return 2;

        case RULE_TYPE::Op_Absolute:
        case RULE_TYPE::Op_AbsoluteX:
        case RULE_TYPE::Op_AbsoluteY:
        case RULE_TYPE::Op_Indirect:
        case RULE_TYPE::Op_ZeroPageRelative:
            return 3;

        default:
            return 1;
    }
}

/**
 * @brief Runs multi-pass symbol resolution until convergence or max pass limit.
 * @param statements AST statement stream.
 * @param anonymous_labels Anonymous label tracker.
 * @param src_mgr Source code manager.
 * @throws std::runtime_error On convergence failure after max_passes.
 */
void MultiPassAssembler::Assemble(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {
    pass = 1;
    changed = true;
    island_counter = 0;
    stable = false;
    auto lastpasschanged = false;

    if (options.verbose) {
        std::cout << "--- Starting Multi-Pass Symbol Resolution ---\n";
    }

    for (auto&sym : options.traced_symbols) {
        symbols_.Trace(sym);
        vars_.Trace(sym);
    }
    for (auto&[sym, val] : options.defined_symbols) {
        changed |= symbols_.Define(sym, static_cast<uint16_t>(val));
    }

    while ((changed || (wait_stable && !stable)) && pass <= max_passes) {

        lastpasschanged = changed;
        stable = !lastpasschanged;

        parent_scope="GLOBAL_";
        changed = ResolutionPass(statements, anonymous_labels, src_mgr);
        if (options.verbose) {
            std::cout << "Pass " << pass << " complete. "
                << (changed ? "Symbols modified (needs another pass)." : "Symbols stable.") << "\n";
        }
        pass++;
        if (wait_stable && stable) {
            wait_stable = false;
        }
    }

    if (changed) {
        throw std::runtime_error("Symbol resolution failed to converge after " + std::to_string(max_passes) +" passes.");
    }

    parent_scope="GLOBAL_";
    EmitFinalPass(statements, anonymous_labels, src_mgr);
}

/**
 * @brief Main AST worker node processor for multi-pass evaluation and branch relaxation.
 * @param statements Original statement AST.
 * @param new_statements Target statement queue for current pass.
 * @param st_index Current instruction pointer within `statements`.
 * @param anonymous_labels Anonymous label mapping.
 * @param src_mgr Source location manager.
 */
void MultiPassAssembler::ProcessStatement(std::vector<std::unique_ptr<Statement>>& statements, std::vector<std::unique_ptr<Statement>>&new_statements, size_t& st_index, 
    std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) 
{
    std::unique_ptr<Statement>&stmt = statements[st_index];    
    if (!stmt) {
        st_index++; 
        return; 
    }

    switch(stmt->stmt_type) {
        case StmtType::Label : {
            // Label
            auto lbl = static_cast<const LabelStatement*>(stmt.get());
            auto name = lbl->name;

            if (lbl->is_anon()) {
                std::pair<int, size_t> stmt_id = { stmt->file, stmt->line };
                auto it = anon_idmap.find(stmt_id);
                if (it == anon_idmap.end()) {
                    anonymous_labels.push_back({
                        .type = name[0],
                        .address = pc,
                        .statement_id = stmt_id
                    });
                    anon_idmap[stmt_id] = anonymous_labels.size() -1;
                    changed = true;
                }
                else {
                    auto index = it->second;
                    if (anonymous_labels[index].address != pc) {
                        anonymous_labels[index].address = pc;
                        changed = true;
                    }
                }
                new_statements.push_back(std::move(stmt));
            }
            else {
                if (lbl->is_local()) {
                    name = GetMangledSymbol(name, parent_scope);
                }
                else if (!lbl->is_anon()) {
                    parent_scope = name;
                }
                if (vars_.Lookup(name)) {

                    throw std::runtime_error(
                        std::format("should not be a label at ${:04X} File: {} Line: {}", 
                                    pc, src_mgr.GetFileName(lbl->file), lbl->line));
                }
                else {
                    changed |= symbols_.Define(name, pc);
                }
                new_statements.push_back(std::move(stmt));
            }
            break;
        }

        case StmtType::Org: {
           // Org
            auto org = static_cast<const OrgStatement*>(stmt.get());
            if (org->address_expr) {
                auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                if (val.has_value()) pc = static_cast<uint16_t>(val.value());
            }
            new_statements.push_back(std::move(stmt));
            break;
        }

        case StmtType::Var: {
            auto var_stmt = static_cast<const VarStatement*>(stmt.get());            
            for (const auto& [name, expr] : var_stmt->vars) {
                int64_t initial_val = 0;

                if (expr) {
                    auto val = EvaluateExpr(expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                    if (val.has_value()) {
                        initial_val = val.value();
                    } else {
                        // If expression fails during pass evaluation, report error or default
                        throw std::runtime_error(
                            std::format("Invalid initializer expression for variable '{}' at File: {} Line {}", 
                            name, src_mgr.GetFileName(var_stmt->file), var_stmt->line));
                    }
                }

                // CRITICAL: Always register 'name' in vars_, even if 0, so vars_.Lookup(name) succeeds
                vars_.Define(name, static_cast<uint16_t>(initial_val));
            }
            new_statements.push_back(std::move(stmt));
            break;
        }
        
        case StmtType::Equ: {
            // Equ
            auto equ = static_cast<const EquStatement*>(stmt.get());
            if (equ->value_expr) {
                auto name = equ->name;
                if (equ->is_local()) {
                    name = GetMangledSymbol(name, parent_scope);
                }
                auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                if (val.has_value()) {                   
                    if (vars_.Lookup(name)) {
                        vars_.Define(name, static_cast<uint16_t>(val.value()));
                    }
                    else {
                        changed |= symbols_.Define(name, static_cast<uint16_t>(val.value()));
                    }
                }
            }
            new_statements.push_back(std::move(stmt));
            break;
        }

        case StmtType::Ds: {
            // Ds
            auto ds = static_cast<const DsStatement*>(stmt.get());
            if (ds->size_expr) {
                auto val = EvaluateExpr(ds->size_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                if (val.has_value()) {
                    pc += val.value();
                }
            }
            new_statements.push_back(std::move(stmt));
            break;
        }

        case StmtType::Data: {
            // Data
            auto data = static_cast<const DataStatement*>(stmt.get());
            uint16_t bytes_per_elem = (data->width == DataWidth::Byte) ? 1 : 2;
            pc += static_cast<uint16_t>(data->elements.size() * bytes_per_elem);
            new_statements.push_back(std::move(stmt));
            break;
        }

        case StmtType::Fill: {
            // Fill
            // Transform FillStatement -> DataStatement
            auto fill = static_cast<const FillStatement*>(stmt.get());
            if (fill->byte_expr && fill->length_expr) {
                auto byt = EvaluateExpr(fill->byte_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                auto len = EvaluateExpr(fill->length_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);

                if (byt.has_value() && len.has_value()) {
                    std::vector<std::unique_ptr<ExprNode>> elems;
                    auto b = byt.value();

                    for (auto i = 0; i < len.value(); ++i) {
                        elems.push_back( std::make_unique<NumberExpr>(static_cast<uint8_t>(b)));
                    }

                    // Create DataStatement preserving line & source string metadata
                    auto data_stmt = std::make_unique<DataStatement>(
                        fill->file, fill->line, DataWidth::Byte, std::move(elems)
                    );
                    pc += static_cast<uint16_t>(elems.size());
                    new_statements.push_back(std::move(data_stmt));
                }
                else {
                    // Keep FillStatement for next pass if expressions couldn't resolve yet
                    new_statements.push_back(std::move(stmt));
                }
            }
            break;
        }

        case StmtType::Break: {
            loopControl = LoopControlKind::break_loop;
            new_statements.push_back(std::move(stmt));
            break;
        }
            
        case StmtType::Continue: {
            loopControl = LoopControlKind::continue_loop;
            new_statements.push_back(std::move(stmt));
            break;
        }
            
        case StmtType::Loop: 
        {
            auto loop_statement = static_cast<LoopStatement*>(stmt.get());

            if (!loop_statement->condition_expr) {
                throw std::runtime_error(
                    std::format("loop expression must be predefined at ${:04X} File: {} Line: {}", 
                                pc, src_mgr.GetFileName(loop_statement->file), loop_statement->line));
            }

            // Helper lambda to check if a statement is a loop start
            auto is_loop_start = [&](const std::unique_ptr<Statement>& s) {
                return s->stmt_type == StmtType::Loop || s->stmt_type == loop_statement->loop_start_keyword;
            };

            // Helper lambda to check if a statement is a loop end
            auto is_loop_end = [&](const std::unique_ptr<Statement>& s) {
                return s->stmt_type == StmtType::Wend || s->stmt_type == loop_statement->loop_end_keyword;
            };

            // 1. Capture original loop body template ONCE (depth-aware)
            if (loop_statement->statements.empty()) {
                size_t scan_idx = st_index + 1;
                int depth = 1;

                while (scan_idx < statements.size() && statements[scan_idx] && depth > 0) {
                    if (is_loop_start(statements[scan_idx])) {
                        depth++;
                    } else if (is_loop_end(statements[scan_idx])) {
                        depth--;
                        if (depth == 0) {
                            break; // Matched outer end keyword
                        }
                    }
                    loop_statement->statements.push_back(statements[scan_idx]->clone());
                    scan_idx++;
                }
            }

            loopControl = LoopControlKind::normal;
            // 2. Unroll loop iterations into new_statements for THIS pass
            int iteration_count = 0;
            const int MAX_ITERATIONS = 64000;

            while (iteration_count < MAX_ITERATIONS) {
                if (loop_statement->test_at_top) {
                    auto condition = EvaluateExpr(loop_statement->condition_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);

                    if (!condition.has_value()) {
                        throw std::runtime_error(
                            std::format("loop expression could not be evaluated at ${:04X} File: {} Line: {}", 
                                        pc, src_mgr.GetFileName(loop_statement->file), loop_statement->line));
                    }

                    auto v = condition.value();
                    auto exitloop = loop_statement->reverse_logic ? v != 0 : v == 0;
                    if (exitloop ) {
                        break; 
                    }
                }

                std::vector<std::unique_ptr<Statement>> iteration_body;
                for (const auto& body_stmt : loop_statement->statements) {
                    if (body_stmt) {
                        iteration_body.push_back(body_stmt->clone());
                    }
                }

                size_t inner_index = 0;
                while (inner_index < iteration_body.size()) {
                 
                    ProcessStatement(iteration_body, new_statements, inner_index, anonymous_labels, src_mgr);
                    if (loopControl == LoopControlKind::break_loop) {
                        break;
                    }
                    else if (loopControl == LoopControlKind::continue_loop) {
                        loopControl = LoopControlKind::normal;
                        break;
                    }
                }
                if (loopControl == LoopControlKind::break_loop) {
                    loopControl = LoopControlKind::normal;
                    break;
                }

                if (!loop_statement->test_at_top) {
                    auto condition = EvaluateExpr(loop_statement->condition_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);

                    if (!condition.has_value()) {
                        throw std::runtime_error(
                            std::format("loop expression could not be evaluated at ${:04X} File: {} Line: {}", 
                                        pc, src_mgr.GetFileName(loop_statement->file), loop_statement->line));
                    }

                    auto v = condition.value();
                    auto exitloop=loop_statement->reverse_logic ? v != 0 : v == 0;
                    if (exitloop) {
                        break; 
                    }
                }

                iteration_count++;
            }

            if (iteration_count >= MAX_ITERATIONS) {
                throw std::runtime_error(
                    std::format("infinite loop detected at ${:04X} File: {} Line: {}", 
                                pc, src_mgr.GetFileName(loop_statement->file), loop_statement->line));
            }

            // 3. Advance driver index to the matching outer end statement (depth-aware)
            size_t skip_idx = st_index + 1;
            int skip_depth = 1;

            while (skip_idx < statements.size() && statements[skip_idx] && skip_depth > 0) {
                if (is_loop_start(statements[skip_idx])) {
                    skip_depth++;
                } else if (is_loop_end(statements[skip_idx])) {
                    skip_depth--;
                    if (skip_depth == 0) {
                        break;
                    }
                }
                skip_idx++;
            }
            
            st_index = skip_idx;
            break;
        }

        case StmtType::Instruction: {
            // Instruction
            auto inst = static_cast<InstructionStatement*>(stmt.get());
            const OpCodeInfo* info = FindOpCodeInfo(inst->mnemonic);
            if (!info) {
                throw std::runtime_error(
                std::format("Unknown opcode '{}'  at ${:04X}  File: {} Line: {}", inst->mnemonic, pc, src_mgr.GetFileName(inst->file), inst->line));
            }

            auto mode_it = info->mode_to_opcode.find(inst->mode);
            if (mode_it == info->mode_to_opcode.end()) {
                
                switch (inst->mode) {
                    case RULE_TYPE::Op_Implied:
                        mode_it = info->mode_to_opcode.find(RULE_TYPE::Op_Accumulator);
                        break;
                        
                    case RULE_TYPE::Op_Absolute:
                        mode_it = info->mode_to_opcode.find(RULE_TYPE::Op_ZeroPage);
                        break;
                     
                    case RULE_TYPE::Op_AbsoluteX:
                        mode_it = info->mode_to_opcode.find(RULE_TYPE::Op_ZeroPageX);
                        break;
                     
                    case RULE_TYPE::Op_AbsoluteY:
                        mode_it = info->mode_to_opcode.find(RULE_TYPE::Op_ZeroPageY);
                        break;
                     
                    default:
                        break;
                }
                if (mode_it == info->mode_to_opcode.end()) {
                    throw std::runtime_error(
                        std::format("Unsupported mode for opcode '{}'  at ${:04X}  File: {} Line: {}", inst->mnemonic, pc, src_mgr.GetFileName(inst->file), inst->line));
                    }
                }
                auto val = EvaluateExpr(inst->operand.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                if (val.has_value()) {
                    int64_t evaluated = val.value();
                    if (inst->mode == RULE_TYPE::Op_Relative) {
                        int64_t offset = evaluated - (static_cast<int64_t>(pc) + 2);

                        if (offset < -128 || offset > 127) {
                            // wait for all symbols to resolve first
                            wait_stable = true;
                        }
                        // wait passes to resolve first
                        if (stable && (offset < -128 || offset > 127)) {
                             auto target = evaluated;
                             if (offset > 0) {
                                 target += 3; // add jump island jmp $xxxx
                             }
                             std::string skip_label = std::format("@__island{}", ++ island_counter);

                            auto it = inverted_branches.find(inst->mnemonic);
                            if (it != inverted_branches.end()) {
                                if (options.verbose) {
                                    std::cout <<
                                        "Warning: Branch out of range for '" << inst->mnemonic << "' $" << std::hex << target << std::dec << " [" << offset << "] " <<
                                        "at $" << std::hex << pc << " File: " << src_mgr.GetFileName(inst->file) << " Line: " << std::dec << inst->line <<  "\n";
                                }
                                // 1. Create the JMP statement FIRST by moving the original target expression
                                auto jmp_inst = std::make_unique<InstructionStatement>(
                                    stmt->file,
                                    stmt->line,
                                    "jmp",
                                    RULE_TYPE::Op_Absolute,
                                    std::move(inst->operand) // Safely transfers the unique_ptr ownership to jmp_inst
                                );

                                // 2. create inverted branch
                                auto branch_inst = std::make_unique<InstructionStatement>(
                                    stmt->file,
                                    stmt->line,
                                    it->second,
                                    RULE_TYPE::Op_Relative,
                                    std::make_unique<SymbolExpr>(skip_label)
                                );

                                // 3. create the target label
                                auto label_inst = std::make_unique<LabelStatement>(
                                    stmt->file,
                                    stmt->line,
                                    skip_label
                                );

                                // 4. adjust the pc
                                pc += GetInstructionSize(RULE_TYPE::Op_Relative);
                                pc += GetInstructionSize(RULE_TYPE::Op_Absolute);

                                // 5. Push the new branch first, followed immediately by the new JMP and label
                                new_statements.push_back(std::move(branch_inst));
                                new_statements.push_back(std::move(jmp_inst));
                                new_statements.push_back(std::move(label_inst));
                                break;
                            }
                        }
                    }
                    else { // range check and optimize for page zero
                        if (!options.ignore_size && ((evaluated < 0 || evaluated > 0xFFFF))) {
                            throw std::runtime_error(
                                std::format("Operand out of range for '{}'  at ${:04X} File: {} Line: {}", inst->mnemonic, pc,  src_mgr.GetFileName(inst->file), inst->line)
                            );
                        }
                        RULE_TYPE want_mode = inst->mode;
                        if (evaluated <= 0xFF) {
                            if (inst->mode == Op_Absolute) want_mode = Op_ZeroPage;
                            else if (inst->mode == Op_AbsoluteX) want_mode = Op_ZeroPageX;
                            else if (inst->mode == Op_AbsoluteY) want_mode = Op_ZeroPageY;

                            if (want_mode != inst->mode) {
                                mode_it = info->mode_to_opcode.find(want_mode);
                                if (mode_it != info->mode_to_opcode.end()) {
                                    inst->mode = want_mode;
                                }
                            }
                        }
                        else {
                            if (inst->mode == Op_ZeroPage) want_mode = Op_Absolute;
                            else if (inst->mode == Op_ZeroPageX) want_mode = Op_AbsoluteX;
                            else if (inst->mode == Op_ZeroPageY) want_mode = Op_AbsoluteY;

                            if (want_mode != inst->mode) {
                                mode_it = info->mode_to_opcode.find(want_mode);
                                if (mode_it != info->mode_to_opcode.end()) {
                                    inst->mode = want_mode;
                                }
                                else {
                                    throw std::runtime_error(
                                        std::format("Operand out of range for '{}'  at ${:04X}  File: {} Line: {}", inst->mnemonic, pc, src_mgr.GetFileName(inst->file), inst->line)
                                );
                            }
                        }
                    }
                }
            }
            pc += GetInstructionSize(inst->mode);
            new_statements.push_back(std::move(stmt));
            break;
        }

        case StmtType::Until:
        case StmtType::Wend: {
            // Wend
            break;
        }

        case StmtType::If: {
            auto if_stmt = static_cast<IfStatement*>(stmt.get());

            if (!if_stmt->condition_expr) {
                throw std::runtime_error(
                    std::format("'if' condition expression missing at ${:04X} File: {} Line: {}", 
                                pc, src_mgr.GetFileName(if_stmt->file), if_stmt->line));
            }

            // 1. Capture 'then' and 'else' statement bodies (depth-aware) if not pre-populated
            if (if_stmt->then_statements.empty() && if_stmt->else_statements.empty()) {
                size_t scan_idx = st_index + 1;
                int depth = 1;
                bool in_else = false;

                while (scan_idx < statements.size() && statements[scan_idx] && depth > 0) {
                    auto st_type = statements[scan_idx]->stmt_type;

                    if (st_type == StmtType::If) {
                        depth++;
                    } else if (st_type == StmtType::EndIf) {
                        depth--;
                        if (depth == 0) {
                            break; // Matched outer endif
                        }
                    } else if (st_type == StmtType::Else && depth == 1) {
                        if (in_else) {
                            throw std::runtime_error(
                                std::format("duplicate 'else' directive at ${:04X} File: {} Line: {}", 
                                            pc, src_mgr.GetFileName(statements[scan_idx]->file), statements[scan_idx]->line));
                        }
                        in_else = true;
                        scan_idx++;
                        continue;
                    }

                    if (in_else) {
                        if_stmt->else_statements.push_back(statements[scan_idx]->clone());
                    } else {
                        if_stmt->then_statements.push_back(statements[scan_idx]->clone());
                    }
                    scan_idx++;
                }

                if (depth != 0) {
                    throw std::runtime_error(
                        std::format("unmatched 'if' directive at ${:04X} File: {} Line: {}", 
                                    pc, src_mgr.GetFileName(if_stmt->file), if_stmt->line));
                }
            }

            // 2. Evaluate condition expression for current pass
            auto condition = EvaluateExpr(if_stmt->condition_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);

            if (!condition.has_value()) {
                throw std::runtime_error(
                    std::format("'if' condition could not be evaluated at ${:04X} File: {} Line: {}", 
                                pc, src_mgr.GetFileName(if_stmt->file), if_stmt->line));
            }

            // 3. Recursively process only the active branch into new_statements
            const auto& active_branch = (condition.value() != 0) ? if_stmt->then_statements : if_stmt->else_statements;

            std::vector<std::unique_ptr<Statement>> branch_body;
            for (const auto& body_stmt : active_branch) {
                if (body_stmt) {
                    branch_body.push_back(body_stmt->clone());
                }
            }

            size_t inner_index = 0;
            while (inner_index < branch_body.size()) {
                ProcessStatement(branch_body, new_statements, inner_index, anonymous_labels, src_mgr);
            }

            // 4. Advance driver index to matching outer 'endif'
            size_t skip_idx = st_index + 1;
            int skip_depth = 1;

            while (skip_idx < statements.size() && statements[skip_idx] && skip_depth > 0) {
                auto st_type = statements[skip_idx]->stmt_type;
                if (st_type == StmtType::If) {
                    skip_depth++;
                } else if (st_type == StmtType::EndIf) {
                    skip_depth--;
                    if (skip_depth == 0) {
                        break;
                    }
                }
                skip_idx++;
            }

            st_index = skip_idx;
            break;
        }

        case StmtType::Else: {
            throw std::runtime_error(
                std::format("unexpected 'else' directive without matching 'if' at ${:04X} File: {} Line: {}", 
                            pc, src_mgr.GetFileName(stmt->file), stmt->line));
        }

        case StmtType::EndIf: {
            throw std::runtime_error(
                std::format("unexpected 'endif' directive without matching 'if' at ${:04X} File: {} Line: {}", 
                            pc, src_mgr.GetFileName(stmt->file), stmt->line));
        }

        case StmtType::Print: {
            // Print
            new_statements.push_back(std::move(stmt));
            break;
        }

        default: {
            throw std::runtime_error(
                std::format("Unknown statement at ${:04X}  File: {} Line: {}", pc, src_mgr.GetFileName(stmt->file), stmt->line)
            );
            // never going to get here. Place holder If we want warning instead of error
            // new_statements.push_back(std::move(stmt));
            break;
        }
    }
    st_index++;
}

/**
 * @brief Driver loop for a single symbol resolution pass.
 * @return True if state mutated during this pass, forcing another pass.
 */
bool MultiPassAssembler::ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {
  
    vars_.clear();
    loopControl = LoopControlKind::normal;
    
    changed = false;
    std::vector<std::unique_ptr<Statement>> new_statements;
    new_statements.reserve(statements.size());

    pc = start_pc_;

    size_t st_index = 0;    
    while (st_index < statements.size()) {
        ProcessStatement(statements, new_statements, st_index, anonymous_labels, src_mgr);
    }
    statements = std::move(new_statements);
    return changed;
}

/**
 * @brief Formats a 6502 operand into its standard assembly string representation.
 *
 * Takes a target addressing mode and an evaluated numerical value, returning a formatted
 * syntax string matching standard 6502 assembly conventions (e.g., "#$FF", "$1234,X", "($00,X)").
 *
 * @param mode The addressing mode of the instruction operand (`RULE_TYPE`).
 * @param val The 64-bit evaluated numerical value or target address for the operand.
 * @param val2 The 64-bit evaluated numerical value or target address for the ZeroPageRelative operand.
 * @return A `std::string` containing the formatted operand representation, or an empty string 
 *         for implied or unhandled modes.
 */
 std::string MultiPassAssembler::FormatOperand(RULE_TYPE mode, int64_t val, int64_t val2 = 0) {
    uint16_t v = static_cast<uint16_t>(val);
    uint16_t v2 = static_cast<uint16_t>(val2);
    switch (mode) {
    case RULE_TYPE::Op_Immediate:
        return std::format("#${:02X}", v & 0xFF);
    case RULE_TYPE::Op_ZeroPage:
        return std::format("${:02X}", v & 0xFF);
    case RULE_TYPE::Op_ZeroPageX:
        return std::format("${:02X},X", v & 0xFF);
    case RULE_TYPE::Op_ZeroPageY:
        return std::format("${:02X},Y", v & 0xFF);
    case RULE_TYPE::Op_Absolute:
        return std::format("${:04X}", v);
    case RULE_TYPE::Op_AbsoluteX:
        return std::format("${:04X},X", v);
    case RULE_TYPE::Op_AbsoluteY:
        return std::format("${:04X},Y", v);
    case RULE_TYPE::Op_Indirect:
        return std::format("(${:04X})", v);
    case RULE_TYPE::Op_IndirectX:
        return std::format("(${:02X},X)", v & 0xFF);
    case RULE_TYPE::Op_IndirectY:
        return std::format("(${:02X}),Y", v & 0xFF);
    case RULE_TYPE::Op_Relative:
        return std::format("${:04X}", v);
    case RULE_TYPE::Op_ZeroPageRelative:
        return std::format("${:02X}, ${:04X}", v, v2);
    case RULE_TYPE::Op_Accumulator:
        return "A";
    case RULE_TYPE::Op_Implied:
    default:
        return "";
    }
}

/**
 * @brief Performs the final pass of assembly, generating binary machine code and the assembly listing.
 *
 * Iterates through the AST statement collection to evaluate final symbol/variable expressions, 
 * compute relative branch offsets, emit machine code bytes into the target binary buffer, 
 * and assemble a formatted multi-column assembly listing output (`listing_file`).
 *
 * @param statements A vector of unique pointers to AST `Statement` objects representing the source.
 * @param anonymous_labels Vector of resolved anonymous label references.
 * @param src_mgr Reference to the `SourceManager` instance for retrieving original line text and file names.
 *
 * @throws std::runtime_error If print stack underflows, unknown print directives are encountered,
 *                            symbols/expressions fail to evaluate, relative branches exceed [-128, 127],
 *                            operands exceed address size limits, or PC attempts to move backward.
 */
void MultiPassAssembler::EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {
    vars_.clear();
    loopControl = LoopControlKind::normal;
    pc = start_pc_;
    std::ostringstream listing;

    listing << "\n========================================================================================================================\n";
    listing << "                                                    ASSEMBLY LISTING\n";
    listing << "========================================================================================================================\n";
    listing << "LINE   ADDR   BYTES          SIMPLIFIED LISTING             ORIGINAL SOURCE\n";
    listing << "------------------------------------------------------------------------------------------------------------------------\n";

    std::stack<bool> pr_stack;
    auto printstate = true;

    std::map<int, int> file_last_printed_line;
    int last_file = -1;

    for (const auto& stmt : statements) {
        if (!stmt) continue;

        if (stmt->stmt_type == StmtType::Print) {
            // 1. Process Print Directives FIRST (Must remain completely silent)
            auto prn = dynamic_cast<const PrintStatement*>(stmt.get());
            switch (prn->cmd) {
                case PrintCmd::on:   printstate = true;  break;
                case PrintCmd::off:  printstate = false; break;
                case PrintCmd::push: pr_stack.push(printstate); break;
                case PrintCmd::pop:
                    if (pr_stack.empty()) {
                        throw std::runtime_error(std::format("print stack underflow File: {} Line: {}", src_mgr.GetFileName(prn->file), prn->line));
                    }
                    printstate = pr_stack.top();
                    pr_stack.pop();
                    break;

                default:
                    throw std::runtime_error(std::format("unknown print directive File: {} Line: {}", src_mgr.GetFileName(prn->file), prn->line));
            }

            file_last_printed_line[stmt->file] = stmt->line;
            continue;
        }

        // Helper to catch up unprinted lines (comments, blank lines)
        auto sync_file_and_line_catchup = [&](int target_line) {
            if (stmt->file != last_file) {
                listing << "Processing " << src_mgr.GetFileName(stmt->file) << "\n";
                last_file = stmt->file;
            }

            int& last_printed = file_last_printed_line[stmt->file];
            while (last_printed + 1 < target_line) {
                last_printed++;
                std::string src_text = src_mgr.GetLine(stmt->file, last_printed);
                // Empty ADDR, BYTES, and SIMPLIFIED columns for skipped lines
                listing << std::format("{:5d}) {:7}{:14} {:30} {}\n", last_printed, "", "", "", src_text);
            }
        };

        // Helper to emit a formatted listing row containing all 5 columns
        auto emit_listing_row = [&](uint16_t row_pc, const std::string& hex_bytes, const std::string& simplified_stmt) {
            sync_file_and_line_catchup(stmt->line);

            int& last_printed = file_last_printed_line[stmt->file];
            if (last_printed < stmt->line) {
                // First row for this source line -> Include original source text
                std::string src_text = src_mgr.GetLine(stmt->file, stmt->line);
                listing << std::format("{:5d}) ${:04X}  {:14} {:30} {}\n", stmt->line, row_pc, hex_bytes, simplified_stmt, src_text);
                last_printed = stmt->line;
            } else {
                // Continuation row (e.g. 2nd chunk of a large .byte directive)
                listing << std::format("       ${:04X}  {:14} {:30}\n", row_pc, hex_bytes, simplified_stmt);
            }
        };

        // helper to write bytes to output
        auto emit_bytes = [&](std::vector<uint8_t>& emitted_bytes) {
            if (!load_address_set) {
                load_address = pc;
                load_address_set = true;
            }

            auto sz = binary_output.size();
            if (sz + load_address < pc) {
                auto bytes = pc - load_address - binary_output.size();
                std::vector<uint8_t> ds_data(bytes, 0);
                if (options.verbose)  {
                    std::cout << "Warning inserting " << bytes << " bytes.\n";
                }
                binary_output.insert(binary_output.end(), ds_data.begin(), ds_data.end());
            }
            else if (sz + load_address > pc) {
                throw std::runtime_error(
                    std::format("Can not move PC backwards and insert data PC {}  File: {}  Line:{}", pc, src_mgr.GetFileName(stmt->file), stmt->line)
                );
            }
            binary_output.insert(binary_output.end(), emitted_bytes.begin(), emitted_bytes.end());
            pc += emitted_bytes.size();
        };

        auto stmt_type = stmt->stmt_type;
        // ---------------------------------------------------------------------
        // Statement Listing Generation
        // ---------------------------------------------------------------------
        switch (stmt_type) {
            case StmtType::Label: {
                // 1. Label Statements
                auto lbl = static_cast<const LabelStatement*>(stmt.get());
                if (printstate) {
                     emit_listing_row(pc, "", lbl->name);
                }
                else {
                    file_last_printed_line[stmt->file] = stmt->line;
                }

                if (!lbl->is_local() && !lbl->is_anon()) {
                    parent_scope = lbl->name;
                }
                break;
            }

            case StmtType::Org: {
                // 2. Org Directives (*= $XXXX)
                auto org = static_cast<const OrgStatement*>(stmt.get());
                if (org->address_expr) {
                    auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                    if (!val.has_value()) {
                        throw std::runtime_error(
                            std::format("Invalid value File: {}  Line:{}", src_mgr.GetFileName(stmt->file), stmt->line)
                        );
                    }
                    pc = static_cast<uint16_t>(val.value());
                }
                if (printstate) {
                    emit_listing_row(pc, "", std::format("*= ${:04X}", pc));
                }
                else {
                    file_last_printed_line[stmt->file] = stmt->line;
                }
                break;
            }

            case StmtType::Equ: {
                // 3. Equate Directives (NAME = $VAL)
                auto equ = static_cast<const EquStatement*>(stmt.get());
                uint16_t v = 0;
                if (equ->value_expr) {
                    auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                    if (!val.has_value()) {
                        throw std::runtime_error(
                            std::format("Invalid value File: {}  Line:{}", src_mgr.GetFileName(stmt->file), stmt->line)
                        );
                    }
                    v = static_cast<uint16_t>(val.value());
                    
                    if (vars_.Lookup(equ->name)) {
                        vars_.Define(equ->name, v);
                    }
                    else {
                        symbols_.Define(equ->name, v);
                    }
                }
                if (printstate) {
                    emit_listing_row(v, "", std::format("{} = ${:04X}", equ->name, v));
                }
                else {
                    file_last_printed_line[stmt->file] = stmt->line;
                }
                break;
            }

            case StmtType::Data: {
                // 4. Data Directives (.byte / .word)
                auto data = static_cast<const DataStatement*>(stmt.get());
                uint16_t current_pc = pc;
                std::vector<uint8_t> data_bytes;
                std::vector<std::string> elem_strs;

                for (const auto& expr : data->elements) {
                    if (!expr) continue;
                    auto val = EvaluateExpr(expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                    int64_t v = val.value_or(0);

                    if (data->width == DataWidth::Byte) {
                        uint8_t b = static_cast<uint8_t>(v & 0xFF);
                        data_bytes.push_back(b);
                        elem_strs.push_back(std::format("${:02X}", b));
                    } else {
                        uint8_t low = static_cast<uint8_t>(v & 0xFF);
                        uint8_t high = static_cast<uint8_t>((v >> 8) & 0xFF);
                        data_bytes.push_back(low);
                        data_bytes.push_back(high);
                        elem_strs.push_back(std::format("${:04X}", static_cast<uint16_t>(v & 0xFFFF)));
                    }
                }
                emit_bytes(data_bytes);

                if (!printstate) {
                    file_last_printed_line[stmt->file] = stmt->line;
                    break;
                }

                std::string dir_keyword = (data->width == DataWidth::Byte) ? ".byte" : ".word";
                size_t elems_per_chunk = (data->width == DataWidth::Byte) ? 4 : 2;
                size_t bytes_per_elem = (data->width == DataWidth::Byte) ? 1 : 2;

                for (size_t i = 0; i < elem_strs.size(); i += elems_per_chunk) {
                    size_t elem_count = std::min(elems_per_chunk, elem_strs.size() - i);
                    size_t byte_offset = i * bytes_per_elem;
                    size_t byte_count = elem_count * bytes_per_elem;
                    uint16_t chunk_pc = static_cast<uint16_t>(current_pc + byte_offset);

                    std::string hex_str;
                    for (size_t b = 0; b < byte_count; ++b) {
                        hex_str += std::format("{:02X} ", data_bytes[byte_offset + b]);
                    }

                    std::string chunk_stmt = dir_keyword;
                    for (size_t e = 0; e < elem_count; ++e) {
                        chunk_stmt += (e == 0 ? " " : ", ") + elem_strs[i + e];
                    }

                    emit_listing_row(chunk_pc, hex_str, chunk_stmt);
                }
                break;
            }

            case StmtType::Break:
            case StmtType::Continue:
            case StmtType::Wend:
            case StmtType::Until:
                break;
                
            case StmtType::Ds: {
                // .ds Directives
               auto ds = static_cast<const DsStatement*>(stmt.get());
               auto val = EvaluateExpr(ds->size_expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
               file_last_printed_line[stmt->file] = stmt->line;
                if (val.has_value()) {
                    pc += static_cast<uint16_t>(val.value());
                }
                break;
            }

            case StmtType::Var: {
                auto var_stmt = static_cast<const VarStatement*>(stmt.get());            
                for (const auto& [name, expr] : var_stmt->vars) {
                    int64_t initial_val = 0;

                    if (expr) {
                        auto val = EvaluateExpr(expr.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                        if (val.has_value()) {
                            initial_val = val.value();
                        } else {
                            throw std::runtime_error(
                                std::format("Invalid initializer expression for variable '{}' at File: {} line: {}", 
                                name, src_mgr.GetFileName(var_stmt->file), var_stmt->line));
                        }
                    }

                    // Upsert initial value into vars_
                    vars_.Define(name, static_cast<uint16_t>(initial_val));
                }

                if (printstate) {
                    std::string summary = "";
                    for (const auto& [name, expr] : var_stmt->vars) {
                        if (!summary.empty()) summary += ", ";
                        summary += std::format("{} = ${:04X}", name, vars_.Lookup(name).value_or(0));
                    }
                    emit_listing_row(pc, "", summary);
                }                break;
            }

            case StmtType::Instruction: {
                // 5. Instruction / Opcode Statement
                auto inst_stmt = static_cast<const InstructionStatement*>(stmt.get());

                const auto* info = FindOpCodeInfo(inst_stmt->mnemonic);
                if (!info) {
                    throw std::runtime_error(
                        std::format("Invalid mnemonic {} File: {}  Line:{}", inst_stmt->mnemonic, src_mgr.GetFileName(stmt->file), stmt->line)
                    );
                }

                auto modeIt = info->mode_to_opcode.find(inst_stmt->mode);
                if (modeIt == info->mode_to_opcode.end()) {
                    if (inst_stmt->mode == RULE_TYPE::Op_Implied) {
                        modeIt = info->mode_to_opcode.find(RULE_TYPE::Op_Accumulator);
                    }
                    if (modeIt == info->mode_to_opcode.end()) {
                        throw std::runtime_error(
                            std::format(
                                "Invalid addressing mode for mnemonic '{}' File: {}  Line: {}",
                                inst_stmt->mnemonic,
                                src_mgr.GetFileName(stmt->file), stmt->line
                            )
                        );
                    }
                }

                auto [opcode, _] = modeIt->second;
                std::vector<uint8_t> emitted_bytes = { opcode };
                std::string operand_str;

                if (inst_stmt->operand) {
                    auto eval_result = EvaluateExpr(inst_stmt->operand.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);

                    if (!eval_result.has_value()) {
                        if (options.verbose) {
                            std::cout << listing.str();
                        }
                        throw std::runtime_error(
                            std::format("Unresolved symbol in operand for '{}' at ${:04X} File: {} Line: {}", inst_stmt->mnemonic, pc, src_mgr.GetFileName(stmt->file), stmt->line)
                        );
                    }

                    int val = static_cast<int>(eval_result.value());
                    operand_str = FormatOperand(inst_stmt->mode, val);

                    if (inst_stmt->mode == RULE_TYPE::Op_ZeroPageRelative) {
                        
                        auto eval2_result = EvaluateExpr(inst_stmt->operand2.get(), anonymous_labels, symbols_, vars_, parent_scope, pc);
                        if (!eval2_result.has_value()) {
                            if (options.verbose) {
                                std::cout << listing.str();
                            }
                            throw std::runtime_error(
                                std::format("Unresolved symbol in operand for '{}' at ${:04X} File: {} Line: {}", inst_stmt->mnemonic, pc, src_mgr.GetFileName(stmt->file), stmt->line)
                            );
                        }

                        int val2 = static_cast<int>(eval2_result.value());

                        operand_str = FormatOperand(inst_stmt->mode, val, val2);
                        
                        int next_pc = pc + 3;
                        int offset = val2 - next_pc;

                        if (offset < -128 || offset > 127) {
                            throw std::runtime_error(std::format("Branch out of range: offset is {} File: {} Line: {}", offset, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line));
                        }
                        emitted_bytes.push_back(static_cast<uint8_t>(val));
                        emitted_bytes.push_back(static_cast<uint8_t>(offset & 0xFF));
                    }
                    else if (inst_stmt->mode == RULE_TYPE::Op_Relative) {
                        int next_pc = pc + 2;
                        int offset = val - next_pc;

                        if (offset < -128 || offset > 127) {
                            throw std::runtime_error(std::format("Branch out of range: offset is {} File: {} Line: {}", offset, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line));
                        }
                        emitted_bytes.push_back(static_cast<uint8_t>(offset & 0xFF));
                    }
                    else {
                        auto sz = GetInstructionSize(inst_stmt->mode);
                        switch (sz) {
                            case 2:
                                if (val < -128 || val > 255) {
                                    throw std::runtime_error(std::format("Operand value out of range: val is {} File: {} Line: {}", val, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line));
                                }
                                emitted_bytes.push_back(static_cast<uint8_t>(val & 0xFF));
                                break;
                            case 3:
                                if (val & ~0xFFFF) {
                                    throw std::runtime_error(std::format("Operand value out of range: val is {} File: {} Line: {}", val, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line));
                                }
                                emitted_bytes.push_back(static_cast<uint8_t>(val & 0xFF));
                                emitted_bytes.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
                                break;
                            default:
                                break;
                        }
                    }
                }

                std::string hex_dump;
                for (uint8_t b : emitted_bytes) {
                    hex_dump += std::format("{:02X} ", b);
                }

                std::string full_instruction = inst_stmt->mnemonic;
                if (!operand_str.empty()) {
                    full_instruction += " " + operand_str;
                }
                if (printstate) {
                    emit_listing_row(pc, hex_dump, full_instruction);
                }
                else {
                    file_last_printed_line[stmt->file] = stmt->line;
                }

                emit_bytes(emitted_bytes);
                break;
            }
            default:
                listing << std::format("missing emit bytes for {}\n", static_cast<int>(stmt_type));
                break;
         }
    }

    listing << "------------------------------------------------------------------------------------------------------------------------\n";
    listing << std::format("Emitted {} bytes. Load address ${:04X}.\n", binary_output.size(), load_address);

    listing_file = listing.str();
}
