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
            return 3;

        default:
            return 1;
    }
}

void MultiPassAssembler::Assemble(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {
    size_t pass = 1;
    bool symbols_changed = true;
    const size_t max_passes = 10;

    std::cout << "--- Starting Multi-Pass Symbol Resolution ---\n";

    while (symbols_changed && pass <= max_passes) {
        parent_scope="GLOBAL_";
        symbols_changed = ResolutionPass(statements, anonymous_labels, src_mgr);
        std::cout << "Pass " << pass << " complete. "
            << (symbols_changed ? "Symbols modified (needs another pass)." : "Symbols stable.") << "\n";
        pass++;
    }

    if (symbols_changed) {
        throw std::runtime_error("Symbol resolution failed to converge after " + std::to_string(max_passes) +" passes.");
    }

    parent_scope="GLOBAL_";
    EmitFinalPass(statements, anonymous_labels, src_mgr);
}

bool MultiPassAssembler::ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {
    uint16_t pc = start_pc_;
    bool changed = false;
    std::vector<std::unique_ptr<Statement>> new_statements;
    new_statements.reserve(statements.size());

    // Inversion lookup table for 6502 branches
    static const std::unordered_map<std::string, std::string> inverted_branches = {
        {"bne", "beq"}, {"beq", "bne"},
        {"bcc", "bcs"}, {"bcs", "bcc"},
        {"bvc", "bvs"}, {"bvs", "bvc"},
        {"bmi", "bpl"}, {"bpl", "bmi"}
    };

    for (auto& stmt : statements) {
        if (!stmt) continue;

        if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
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
                else {
                    parent_scope = name;
                }
                changed |= symbols_.Define(name, pc);
                new_statements.push_back(std::move(stmt));
            }
        }

        // Org
        else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
            if (org->address_expr) {
                auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                if (val.has_value()) pc = static_cast<uint16_t>(val.value());
            }
            new_statements.push_back(std::move(stmt));
        }

        // Equ
        else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
            if (equ->value_expr) {
                auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                if (val.has_value()) {
                    changed |= symbols_.Define(equ->name, static_cast<uint16_t>(val.value()));
                }
            }
            new_statements.push_back(std::move(stmt));
        }

        // Ds
        else if (auto ds = dynamic_cast<const DsStatement*>(stmt.get())) {
            if (ds->size_expr) {
                auto val = EvaluateExpr(ds->size_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                if (val.has_value()) {
                    pc += val.value();
                }
            }
            new_statements.push_back(std::move(stmt));
        }

        // Data
        else if (auto data = dynamic_cast<const DataStatement*>(stmt.get())) {
            uint16_t bytes_per_elem = (data->width == DataWidth::Byte) ? 1 : 2;
            pc += static_cast<uint16_t>(data->elements.size() * bytes_per_elem);
            new_statements.push_back(std::move(stmt));
        }

        // Fill
        // Transform FillStatement -> DataStatement
        else if (auto fill = dynamic_cast<const FillStatement*>(stmt.get())) {
            if (fill->byte_expr && fill->length_expr) {
                auto byt = EvaluateExpr(fill->byte_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                auto len = EvaluateExpr(fill->length_expr.get(), anonymous_labels, symbols_, parent_scope, pc);

                if (byt.has_value() && len.has_value()) {
                    std::vector<std::unique_ptr<ExprNode>> elems;
                    auto b = byt.value();
                    auto ll = len.value();

                    for (auto i = 0; i < ll; ++i) {
                        elems.push_back(std::make_unique<NumberExpr>(static_cast<uint8_t>(b)));                    
                    }

                    // Create DataStatement preserving line & source string metadata
                    auto data_stmt = std::make_unique<DataStatement>(
                        fill->file, fill->line, DataWidth::Byte, std::move(elems)
                    );

                    new_statements.push_back(std::move(data_stmt));
                    pc += static_cast<uint16_t>(ll);
                }
                else {
                    // Keep FillStatement for next pass if expressions couldn't resolve yet
                    new_statements.push_back(std::move(stmt));
                }
            }
        }

        // Instruction
        else if (auto inst = dynamic_cast<InstructionStatement*>(stmt.get())) {
            const OpCodeInfo* info = FindOpCodeInfo(inst->mnemonic);
            if (!info) {
                throw std::runtime_error(
                    std::format("Unknown opcode '{}'  at ${:04X}  File: {} Line: {}", inst->mnemonic, pc, src_mgr.GetFileName(inst->file), inst->line));
            }

            auto mode_it = info->mode_to_opcode.find(inst->mode);
            if (mode_it == info->mode_to_opcode.end()) {
                throw std::runtime_error(
                    std::format("Unsupported mode for opcode '{}'  at ${:04X}  File: {} Line: {}", inst->mnemonic, pc, src_mgr.GetFileName(inst->file), inst->line));
            }
            auto val = EvaluateExpr(inst->operand.get(), anonymous_labels, symbols_, parent_scope, pc);
            if (val.has_value()) {
                auto evaluated = val.value();
                if (inst->mode == RULE_TYPE::Op_Relative) {
                    int64_t offset = evaluated - (pc + 2);

                    if (offset < -128 || offset > 127) {
                        auto it = inverted_branches.find(inst->mnemonic);
                        if (it != inverted_branches.end()) {
                        //  std::cout << "Warning: Branch out of range for '" << inst->mnemonic <<  "' [" << offset << "] "
                        //            << " at $" << std::hex << pc << " File: " << src_mgr.GetFileName(inst->file) << " Line: " << std::dec << inst->line <<  "\n";

                            // 1. Create the JMP statement FIRST by moving the original target expression
                            auto jmp_inst = std::make_unique<InstructionStatement>(
                                stmt->file,
                                stmt->line,
                                "jmp",
                                RULE_TYPE::Op_Absolute,
                                std::move(inst->operand) // Safely transfers the unique_ptr ownership to jmp_inst
                            );

                            // 2. Modify the original statement in-place into the inverted branch
                            inst->mnemonic = it->second;
                            inst->mode = RULE_TYPE::Op_Relative;

                            // 3. Refill the now-empty operand with the new relative jump target (+5)
                            inst->operand = std::make_unique<NumberExpr>(pc + 5);

                            // 4. Push the modified branch first, followed immediately by the new JMP
                            new_statements.push_back(std::move(stmt));
                            new_statements.push_back(std::move(jmp_inst));

                            pc += 5;
                            changed = true;
                        }
                    }
                }
                else { // range check and optimize for page zero
                    if (evaluated < 0 || evaluated > 0xFFFF) {
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
        }
        else if (auto pr = dynamic_cast<PrintStatement*>(stmt.get())) {
            new_statements.push_back(std::move(stmt));
        }
        else {
            throw std::runtime_error(
                std::format("Unknown statement at ${:04X}  File: {} Line: {}", pc, src_mgr.GetFileName(stmt->file), stmt->line)
            );
            new_statements.push_back(std::move(stmt));
        }
    }

    statements = std::move(new_statements);
    return changed;
}

// Helper to format 6502 operands based on addressing mode
std::string MultiPassAssembler::FormatOperand(RULE_TYPE mode, int64_t val) {
    uint16_t v = static_cast<uint16_t>(val);
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
    case RULE_TYPE::Op_Accumulator:
        return "A";
    case RULE_TYPE::Op_Implied:
    default:
        return "";
    }
}

template<typename... Args>
std::string dyn_print(std::string_view rt_fmt_str, Args&&... args)
{
    return std::vformat(rt_fmt_str, std::make_format_args(args...));
}

void MultiPassAssembler::EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {

    uint16_t pc = start_pc_;
    std::vector<uint8_t> binary_output;
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

        // 1. Process Print Directives FIRST (Must remain completely silent)
        if (auto prn = dynamic_cast<const PrintStatement*>(stmt.get())) {
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

        // 2. Skip listing generation when printstate is off
        if (!printstate) {
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
                listing << std::format("{:5d}) {:7} {:14} {:30} {}\n", last_printed, "", "", "", src_text);
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

        // ---------------------------------------------------------------------
        // Statement Listing Generation
        // ---------------------------------------------------------------------

        // 1. Label Statements
        if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
            emit_listing_row(pc, "", lbl->name);
            if (!lbl->is_local()) {
                parent_scope = lbl->name;
            }
        }
        // 2. Org Directives (*= $XXXX)
        else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
            if (org->address_expr) {
                auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                if (!val.has_value()) {
                    throw std::runtime_error(
                        std::format("Invalid value File: {}  Line:{}", src_mgr.GetFileName(stmt->file), stmt->line)
                    );
                }
                pc = static_cast<uint16_t>(val.value());
            }
            emit_listing_row(pc, "", std::format("*= ${:04X}", pc));
        }
        // 3. Equate Directives (NAME = $VAL)
        else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
            uint16_t v = 0;
            if (equ->value_expr) {
                auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
                if (!val.has_value()) {
                    throw std::runtime_error(
                        std::format("Invalid value File: {}  Line:{}", src_mgr.GetFileName(stmt->file), stmt->line)
                    );
                }
                v = static_cast<uint16_t>(val.value());
            }
            emit_listing_row(v, "", std::format("{} = ${:04X}", equ->name, v));
        }

        // 4. Data Directives (.byte / .word)
        else if (auto data = dynamic_cast<const DataStatement*>(stmt.get())) {
            uint16_t current_pc = pc;
            std::vector<uint8_t> data_bytes;
            std::vector<std::string> elem_strs;

            for (const auto& expr : data->elements) {
                if (!expr) continue;
                auto val = EvaluateExpr(expr.get(), anonymous_labels, symbols_, parent_scope, pc);
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

            binary_output.insert(binary_output.end(), data_bytes.begin(), data_bytes.end());
            pc += static_cast<uint16_t>(data_bytes.size());

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
        }
        // .ds Directives
        else if (auto ds = dynamic_cast<const DsStatement*>(stmt.get())) {
            auto val = EvaluateExpr(ds->size_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
            emit_listing_row(pc, "", ".ds");
            if (val.has_value()) {
                pc += static_cast<uint16_t>(val.value());
            }
        }
        // 5. Instruction / Opcode Statement
        else if (auto inst_stmt = dynamic_cast<const InstructionStatement*>(stmt.get())) {

            auto* info = FindOpCodeInfo(inst_stmt->mnemonic);
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
                auto eval_result = EvaluateExpr(inst_stmt->operand.get(), anonymous_labels, symbols_, parent_scope, pc);

                if (!eval_result.has_value()) {
                    std::cout << listing.str();
                    throw std::runtime_error(
                        std::format("Unresolved symbol in operand for '{}' at ${:04X} File: {} Line: {}", inst_stmt->mnemonic, pc, src_mgr.GetFileName(stmt->file), stmt->line)
                    );
                }

                int val = static_cast<int>(eval_result.value());
                operand_str = FormatOperand(inst_stmt->mode, val);

                if (inst_stmt->mode == RULE_TYPE::Op_Relative) {
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
                        emitted_bytes.push_back(static_cast<uint8_t>(val & 0xFF));
                        break;
                    case 3:
                        emitted_bytes.push_back(static_cast<uint8_t>(val & 0xFF));
                        emitted_bytes.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
                        break;
                    default:
                        break;
                    }
                }
            }

            binary_output.insert(binary_output.end(), emitted_bytes.begin(), emitted_bytes.end());

            std::string hex_dump;
            for (uint8_t b : emitted_bytes) {
                hex_dump += std::format("{:02X} ", b);
            }

            std::string full_instruction = inst_stmt->mnemonic;
            if (!operand_str.empty()) {
                full_instruction += " " + operand_str;
            }

            emit_listing_row(pc, hex_dump, full_instruction);

            pc += static_cast<uint16_t>(emitted_bytes.size());
        }
    }

    listing << "------------------------------------------------------------------------------------------------------------------------\n";
    listing << std::format("Emitted {} bytes.\n", binary_output.size());

    std::cout << listing.str();
}
