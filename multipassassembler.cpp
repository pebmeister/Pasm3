#include <iostream>
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
		symbols_changed = ResolutionPass(statements, anonymous_labels, src_mgr);
		std::cout << "Pass " << pass << " complete. "
				  << (symbols_changed ? "Symbols modified (needs another pass)." : "Symbols stable.") << "\n";
		pass++;
	}

	if (symbols_changed) {
		throw std::runtime_error("Symbol resolution failed to converge after " + std::to_string(max_passes) +" passes.");
		return;
	}

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

	std::string parent_scope="";

	for (auto& stmt : statements) {
		if (!stmt) continue;

		if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
			auto name = lbl->name;
			if (name[0] == '+' || name[0] == '-' ) {
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
			}
			else if (name[0] == '@') {
				symbols_.Define(GetMangledSymbol(lbl->name, parent_scope), pc);
			}
			else {
				parent_scope = name;
				changed |= symbols_.Define(lbl->name, pc);
			}
			new_statements.push_back(std::move(stmt));
		}
		else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
			if (org->address_expr) {
				auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
				if (val) pc = static_cast<uint16_t>(*val);
			}
			new_statements.push_back(std::move(stmt));
		}
		else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
			if (equ->value_expr) {
				auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
				if (val) changed |= symbols_.Define(equ->name, static_cast<uint16_t>(*val));
			}
			new_statements.push_back(std::move(stmt));
		}
		else if (auto data = dynamic_cast<const DataStatement*>(stmt.get())) {
			uint16_t bytes_per_elem = (data->width == DataWidth::Byte) ? 1 : 2;
			pc += static_cast<uint16_t>(data->elements.size() * bytes_per_elem);
			new_statements.push_back(std::move(stmt));
		}
		else if (auto inst = dynamic_cast<InstructionStatement*>(stmt.get())) {
			const OpCodeInfo* info = FindOpCodeInfo(inst->mnemonic);
			if (!info) {
				new_statements.push_back(std::move(stmt));
				continue;
			}

			auto mode_it = info->mode_to_opcode.find(inst->mode);
			if (mode_it != info->mode_to_opcode.end()) {

				auto val = EvaluateExpr(inst->operand.get(), anonymous_labels, symbols_, parent_scope, pc);
				if (val.has_value()) {
					auto evaluated = val.value();
					if (inst->mode == RULE_TYPE::Op_Relative) {
						int64_t offset = evaluated - (pc + 2);

						if (offset < -128 || offset > 127) {
							auto it = inverted_branches.find(inst->mnemonic);
							if (it != inverted_branches.end()) {
								std::cout << "Warning: Branch out of range for '" << inst->mnemonic
										  << "' at $" << std::hex << pc << " File: " << src_mgr.GetFileName(inst->file) << " Line: " << std::dec << inst->line <<  "\n";

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
								continue;
							}
						}
					}
					else { // range check and optimize for page zero
						if (evaluated < 0 || evaluated > 0xFFFF) {
							throw std::runtime_error(
								std::format("Operand out of range for '{}'  at ${:04X}", inst->mnemonic, pc)
							);
						}
						RULE_TYPE want_type = inst->mode;
						if (evaluated <= 0xFF) {
							if (inst->mode == Op_Absolute) want_type = Op_ZeroPage;
							else if (inst->mode == Op_AbsoluteX) want_type = Op_ZeroPageX;
							else if (inst->mode == Op_AbsoluteY) want_type = Op_ZeroPageY;

							if (want_type != inst->mode) {
								mode_it = info->mode_to_opcode.find(want_type);
								if (mode_it != info->mode_to_opcode.end()) {
									inst->mode = want_type;
								}
							}
						}
						else {
							if (inst->mode == Op_ZeroPage) want_type = Op_Absolute;
							else if (inst->mode == Op_ZeroPageX) want_type = Op_AbsoluteX;
							else if (inst->mode == Op_ZeroPageY) want_type = Op_AbsoluteY;

							if (want_type != inst->mode) {
								mode_it = info->mode_to_opcode.find(want_type);
								if (mode_it != info->mode_to_opcode.end()) {
									inst->mode = want_type;
								}
								else {
									throw std::runtime_error(
										std::format("Operand out of range for '{}'  at ${:04X}", inst->mnemonic, pc)
									);
								}
							}
						}
					}

				}

				pc += GetInstructionSize(inst->mode);
			}
			new_statements.push_back(std::move(stmt));
		}
		else {
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

void MultiPassAssembler::EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr) {

	uint16_t pc = start_pc_;
	std::vector<uint8_t> binary_output;
	std::ostringstream listing;
	std::string parent_scope="";

	listing << "\n===============================================================================\n";
	listing << "                               ASSEMBLY LISTING\n";
	listing << "===============================================================================\n";
	listing << "ADDR    BYTES          STATEMENT\n";
	listing << "-------------------------------------------------------------------------------\n";

	std::stack<bool> pr_stack;

	auto printstate = true;

	for (const auto& stmt : statements) {
		if (!stmt) continue;            
		
		// 1. Label Statements
		if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
			if (printstate)
				listing << std::format("${:04X}                {}\n", pc, lbl->name);
			if (lbl->name[0] != '@') {
				parent_scope = lbl->name;
			}
		}
		// 2. Org Directives (*= $XXXX)
		else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
			if (org->address_expr) {
				auto val = EvaluateExpr(org->address_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
				if (val) pc = static_cast<uint16_t>(*val);
			}
			
			if (printstate)
				listing << std::format("       {:14} *= ${:04X}\n", "", pc);
		}
		// 3. Equate Directives (NAME = $VAL)
		else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
			uint16_t v = 0;
			if (equ->value_expr) {
				auto val = EvaluateExpr(equ->value_expr.get(), anonymous_labels, symbols_, parent_scope, pc);
				v = val ? static_cast<uint16_t>(*val) : 0;
			}
			if (printstate)
				listing << std::format("${:04X}  {:14} {} = ${:04X}\n", v, "", equ->name, v);
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

			// Build full statement string: e.g. ".byte $01, $02, $03"
			std::string dir_keyword = (data->width == DataWidth::Byte) ? ".byte" : ".word";
			std::string full_stmt = dir_keyword;
			for (size_t i = 0; i < elem_strs.size(); ++i) {
				full_stmt += (i == 0 ? " " : ", ") + elem_strs[i];
			}

			// Wrap hex bytes if emitting more than 4 bytes
			constexpr size_t max_bytes_per_line = 4;
			for (size_t i = 0; i < data_bytes.size(); i += max_bytes_per_line) {
				size_t chunk_size = std::min(max_bytes_per_line, data_bytes.size() - i);
				uint16_t chunk_pc = static_cast<uint16_t>(current_pc + i);

				std::string hex_str;
				for (size_t b = 0; b < chunk_size; ++b) {
					hex_str += std::format("{:02X} ", data_bytes[i + b]);
				}

				if (i == 0) {
					if (printstate)
						listing << std::format("${:04X}  {:14} {}\n", chunk_pc, hex_str, full_stmt);
				} else {
					if (printstate)
						listing << std::format("${:04X}  {:14}\n", chunk_pc, hex_str);
				}
			}
		}
		// 5. Instruction / Opcode Statement
		else if (auto inst_stmt = dynamic_cast<const InstructionStatement*>(stmt.get())) {

			auto* info = FindOpCodeInfo(inst_stmt->mnemonic);
			if (!info) {
				throw std::runtime_error(
					std::format("Invalid mnemonic {} File: {}  Line:{}", inst_stmt->mnemonic, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line)
				);
			}

			auto modeIt = info->mode_to_opcode.find(inst_stmt->mode);
			if (modeIt == info->mode_to_opcode.end()) {
				throw std::runtime_error(
					std::format(
						"Invalid addressing mode for mnemonic '{}' File: {}  Line: {}",
						inst_stmt->mnemonic,
						src_mgr.GetFileName(inst_stmt->file), inst_stmt->line
					)
				);
			}

			// Re-use the iterator instead of doing another map lookup with .at()
			auto [opcode, _] = modeIt->second;

			std::vector<uint8_t> emitted_bytes = { opcode };
			std::string operand_str; // Will hold the formatted operand (e.g., "#$32", "$C000")

			if (inst_stmt->operand) {
				auto eval_result = EvaluateExpr(inst_stmt->operand.get(), anonymous_labels, symbols_, parent_scope, pc);

				// Catch unresolved symbols in the final pass


				if (!eval_result.has_value()) {
					std::cout << listing.str();

					throw std::runtime_error(
						std::format("Unresolved symbol in operand for '{}' at ${:04X} File: {} Line: {}", inst_stmt->mnemonic, pc, src_mgr.GetFileName(inst_stmt->file), inst_stmt->line)
					);
				}

				int val = static_cast<int>(eval_result.value());
				operand_str = FormatOperand(inst_stmt->mode, val);

				// Relative mode (Branches) require PC-relative offset calculation
				if (inst_stmt->mode == RULE_TYPE::Op_Relative) {
					int next_pc = pc + 2; // PC after this instruction is read
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

			// Write bytes to the final binary buffer
			binary_output.insert(binary_output.end(), emitted_bytes.begin(), emitted_bytes.end());

			// Format the hex dump for the listing (e.g., "A9 01    ")
			std::string hex_dump;
			for (uint8_t b : emitted_bytes) {
				hex_dump += std::format("{:02X} ", b);
			}

			// Append the operand text to the mnemonic if it exists
			std::string full_instruction = inst_stmt->mnemonic;
			if (!operand_str.empty()) {
				full_instruction += " " + operand_str;
			}

			// Append to listing file with C++20 strict alignment matching your Data format
			if (printstate)
				listing << std::format("${:04X}  {:14} {}\n", pc, hex_dump, full_instruction);

			// Advance the program counter
			pc += static_cast<uint16_t>(emitted_bytes.size());
		}
		else if (auto prn = dynamic_cast<const PrintStatement*>(stmt.get())) {
			switch (prn->cmd) {
			case PrintCmd::on: 
				printstate = true; 
				break;
			case PrintCmd::off: 
				printstate = false; 
				break;							
			case PrintCmd::push:
				pr_stack.push(printstate);
				break;
				
			case PrintCmd::pop:
				if (pr_stack.empty()) {
					throw std::runtime_error(std::format("print stack underflow File: {} Line: {}",  src_mgr.GetFileName(prn->file), prn->line));
				}
				printstate = pr_stack.top();
				pr_stack.pop();
				break;

			default:
				throw std::runtime_error(std::format("unknpow print directive File: {} Line: {}",  src_mgr.GetFileName(prn->file), prn->line));
			}				
		}
		continue;
	}

	listing << "-------------------------------------------------------------------------------\n";
	listing << std::format("Emitted {} bytes.\n", binary_output.size());

	std::cout << listing.str();
}
