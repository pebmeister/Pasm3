#include <chrono>
#include <exception>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <filesystem>
#include <format>
#include <cctype>

#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"

#include "opcode_test.h"
#include "ANSI_esc.h"


int Opcode_test::op_test(OP_TEST& test, int max)
{
    Options options;
    options.verbose = false;

    SourceManager src_mgr;
    PasmTokenizer tokenizer;
    std::vector<uint8_t> expected_output;
    std::unordered_map<std::string, MacroDef> macros_;
    std::vector<AnonymousLabel> anonymous_labels;    
    std::string line;
    std::string source_code;
    std::stringstream ss;

    int line_num = 1;
    int count = 0;
    
    std::string test_name = std::format("{:=>6} {:>4} {:15} {:=>6}", '=', test.op, rulemap[static_cast<RULE_TYPE>(test.mode)], '=');
    line = std::format("; {}\n", test_name);
    src_mgr.source[{fileid, line_num}] = line;
    source_code += (line + "\n");
    line_num++;

    constexpr int org = 0x1000;
    
    std::string orgline = std::format("    * = {}", org);
    line = std::format("{}\n", orgline);
    src_mgr.source[{fileid, line_num}] = line;
    source_code += (line + "\n");
    line_num++;

    // Helper for single-instruction modes (Implied, Accumulator)
    auto emit_single = [&](std::string_view suffix = "") {
        expected_output.push_back(test.expected);
        line = suffix.empty() ? std::format("    {}", test.op) : std::format("    {} {}", test.op, suffix);
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    // Helper for repeating operand loops
    auto emit_loop = [&](auto& opr_ref, auto format_fn, bool is_16bit) {
        while (count < max) {
            expected_output.push_back(test.expected);
            if (is_16bit) {
                expected_output.push_back(opr_ref & 0xFF);
                expected_output.push_back((opr_ref >> 8) & 0xFF);
            } else {
                expected_output.push_back(static_cast<uint8_t>(opr_ref));
            }

            line = std::format("    {} {}", test.op, format_fn(opr_ref));
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;
            
            opr_ref++;
            if (is_16bit) {
                if (opr_ref > abs_max || opr_ref < abs_min) {
                    opr_ref = abs_min;
                }
            }
            count++;
        }
    };

    switch (test.mode) {
        case RULE_TYPE::Op_Implied:
            emit_single();
            break;

        case RULE_TYPE::Op_Accumulator:
            emit_single("A");
            break;
            
        case RULE_TYPE::Op_Immediate:
            emit_loop(opr_immediate, [&](auto v) { return std::format("#${:02X}", v); }, false);
            break;
        
        case RULE_TYPE::Op_ZeroPage:
            emit_loop(opr_zeropage, [&](auto v) { return std::format("${:02X}", v); }, false);
            break;
        
        case RULE_TYPE::Op_Absolute:
            emit_loop(opr_absolute, [&](auto v) { return std::format("${:04X}", v); }, true);
            break;
        
        case RULE_TYPE::Op_AbsoluteX:
            emit_loop(opr_absolutex, [&](auto v) { return std::format("${:04X},X", v); }, true);
            break;

        case RULE_TYPE::Op_ZeroPageX:
            emit_loop(opr_zeropagex, [&](auto v) { return std::format("${:02X},X", v); }, false);
            break;

        case RULE_TYPE::Op_AbsoluteY:
            emit_loop(opr_absolutey, [&](auto v) { return std::format("${:04X},Y", v); }, true);
            break;

        case RULE_TYPE::Op_ZeroPageY:
            emit_loop(opr_zeropagey, [&](auto v) { return std::format("${:02X},Y", v); }, false);
            break;
     
        case RULE_TYPE::Op_Indirect:
            emit_loop(opr_indirect, [&](auto v) { return std::format("(${:04X})", v); }, true);
            break;

        case RULE_TYPE::Op_IndirectX:
            emit_loop(opr_indirectx, [&](auto v) { return std::format("(${:04X},X)", v); }, false);
            break;
            
         case RULE_TYPE::Op_IndirectY:
            emit_loop(opr_indirecty, [&](auto v) { return std::format("(${:04X}),Y", v); }, false);
            break;
     
        
        case RULE_TYPE::Op_Relative:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_relative - rel_offset);

                line = std::format("    {} * + ({})", test.op, opr_relative);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                
                opr_relative++;
                if (opr_relative >= rel_max) {
                    opr_relative = rel_min + rel_offset;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_ZeroPageRelative:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_zprel_addr);
                expected_output.push_back(opr_zprelative - zp_rel_offset);

                line = std::format("    {} ${:02X}, * + ({})", test.op, opr_zprel_addr, opr_zprelative);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_zprel_addr++;
                opr_zprelative++;
                if (opr_zprelative >= rel_max) {
                    opr_zprelative = rel_min + zp_rel_offset;
                }
                count++;
            }
            break;
    
         default:
            break;
    }

    if (org + expected_output.size() >= 0xFFFF) {
        throw std::runtime_error(std::format("PC exceeded. Lower max iteration."));
    }
    
    bool pass = true;
    if (source_code.length() > 0) {        
        try {
            ++test_num;

            auto tokens = tokenizer.tokenize(source_code, fileid);
            AssemblerParser parser(tokens, options);
            auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);
            MultiPassAssembler assembler(options);
            assembler.Assemble(statements, anonymous_labels, src_mgr);
            
            std::vector<RULE_TYPE> false_negative_mode;
            pass = true;
            if (test.negative_test) {
                pass = false;
                
                switch (test.mode) {
                    case RULE_TYPE::Op_ZeroPage:
                        false_negative_mode.push_back(RULE_TYPE::Op_Absolute);
                        false_negative_mode.push_back(RULE_TYPE::Op_Relative);
                        break;
                        
                    case RULE_TYPE::Op_ZeroPageX:
                        false_negative_mode.push_back(RULE_TYPE::Op_AbsoluteX);
                        break;

                    case RULE_TYPE::Op_ZeroPageY:
                        false_negative_mode.push_back(RULE_TYPE::Op_AbsoluteY);
                        break;
                     
                     case RULE_TYPE::Op_Absolute:
                        false_negative_mode.push_back(RULE_TYPE::Op_Relative);
                        break;

                     case RULE_TYPE::Op_Relative:
                        false_negative_mode.push_back(RULE_TYPE::Op_Absolute);
                        false_negative_mode.push_back(RULE_TYPE::Op_ZeroPage);
                        break;
                     
                   default:
                        break;                        
                }
                auto info  = FindOpCodeInfo(test.op);
                if (info != NULL) {
                    for (auto& mode: false_negative_mode) {
                        auto modeIt = info->mode_to_opcode.find(static_cast<RULE_TYPE>(mode));
                        if (modeIt != info->mode_to_opcode.end()) {
                            pass = true;
                            break;                               
                        }         
                    }
                }                
            }
            else {
                if (pass) {
                    pass = expected_output == assembler.binary_output;

                    if (!pass) {
                        ss << "expected:\n";
                        for (auto& eb: expected_output) {
                            ss << std::format(" ${:02X} ", eb);
                        }
                        ss << "\n";
                        ss << "actual:\n";
                        for (auto& eb: assembler.binary_output) {
                            std::cout << std::format(" ${:02X} ", eb);
                        }
                        ss << "\n";                        
                    }
                }
            }
        }
        catch (std::exception& ex) {
            pass = test.negative_test;         
        }
        if (!pass) {
            ss << std::format("TEST {} {} {} {}\n", test_num, test_name, (test.negative_test ? "negative" : ""), "FAIL");
            error = ss.str();
            source = source_code;
            
            std::cout << source;
        }
    }
    return pass;
}

void Opcode_test::build_opcode_tests(std::vector<OP_TEST>& positive_opcode_tests, std::vector<OP_TEST>& negative_opcode_tests)
{
    std::vector<std::string> ops = {
        // Standard 6502 ALU and Memory Operations
        "ORA", "AND", "EOR", "ADC", "SBC",
        "CMP", "CPX", "CPY", "DEC", "DEX",
        "DEY", "INC", "INX", "INY", "ASL",
        "ROL", "LSR", "ROR", "LDA", "STA",
        "LDX", "STX", "LDY", "STY",

        // 65C02 Bit Manipulation Directives
        "RMB0", "RMB1", "RMB2", "RMB3", "RMB4", "RMB5", "RMB6", "RMB7",
        "SMB0", "SMB1", "SMB2", "SMB3", "SMB4", "SMB5", "SMB6", "SMB7",

        // Register Transfers & Stack Operations
        "STZ", "TAX", "TXA", "TAY", "TYA",
        "TSX", "TXS", "PLA", "PHA", "PLP",
        "PHP", "PHX", "PHY", "PLX", "PLY",

        // Control Flow & Branching
        "BRA", "BPL", "BMI", "BVC", "BVS",
        "BCC", "BCS", "BNE", "BEQ",

        // 65C02 Bit Branching Directives
        "BBR0", "BBR1", "BBR2", "BBR3", "BBR4", "BBR5", "BBR6", "BBR7",
        "BBS0", "BBS1", "BBS2", "BBS3", "BBS4", "BBS5", "BBS6", "BBS7",

        // Control & Subroutine Instructions
        "STP", "WAI", "BRK", "RTI", "JSR", 
        "RTS", "JMP", "BIT",

        // Processor Status Flag Operations
        "CLC", "SEC", "CLD", "SED", "CLI",
        "SEI", "CLV", "NOP",

        // Undocumented / Illegal 6502 Opcodes
        "SLO", "RLA", "SRE", "RRA", "SAX",
        "LAX", "DCP", "ISC", "ANC", "ANC2",
        "ALR", "ARR", "XAA", "AXS", "USBC",
        "AHX", "SHY", "SHX", "TAS", "LAS",

        // 65C02 Bit Test & Reset/Set
        "TRB", "TSB"
    };
        
    for (auto& op : ops) {
        auto info  = FindOpCodeInfo(op);
        if (info != NULL) {
            
            for (int mode = RULE_TYPE::Op_Implied; mode <= RULE_TYPE::Op_ZeroPageRelative; ++mode) {
                auto modeIt = info->mode_to_opcode.find(static_cast<RULE_TYPE>(mode));
                if (modeIt == info->mode_to_opcode.end()) {
                    negative_opcode_tests.push_back({op, mode, 0, true});
                }
                else {
                    auto [opcode, _] = modeIt->second;
                    
                    positive_opcode_tests.push_back({op, mode, opcode, false});
                }
            }
        }
    }
}

int Opcode_test::test(int max_iterations, int line, int col, bool exit_on_fail)
{
    std::vector<OP_TEST> positive_opcode_tests;
    std::vector<OP_TEST> negative_opcode_tests;

    build_opcode_tests(positive_opcode_tests, negative_opcode_tests);
    std::vector<std::vector<OP_TEST>> test_suites = { positive_opcode_tests, negative_opcode_tests };

    auto total_tests = positive_opcode_tests.size() + negative_opcode_tests.size();
    

    for (auto& suite : test_suites) {
        for (auto& test : suite) {
            if (op_test(test, max_iterations)) {
                passed++;
            } else {
                failed++;
            }
            if (failed > 0) {
                std::cout << std::format("{}{} {}PASSED: {} {}FAILED: {}", es.pos(line, col), es.ERASE_CURSOR_EOL, 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed, es.gr(es.BRIGHT_RED_FOREGROUND), failed);
                    
                if (exit_on_fail) {
                    return 0;
                }
            } else {
                std::cout << std::format("{}{} {}PASSED: {} of {} ", es.pos(line, col), es.ERASE_CURSOR_EOL, 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed, total_tests);
            }
        }
    }
    return failed == 0;
}
