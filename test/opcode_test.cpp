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


int Opcode_test::op_test(OP_TEST& test, int max, bool negative)
{
    Options options;
    SourceManager src_mgr;
    PasmTokenizer tokenizer;
    std::vector<uint8_t> expected_output;
    std::unordered_map<std::string, MacroDef> macros_;
    std::vector<AnonymousLabel> anonymous_labels;
    
    std::string line;
    std::string source_code;
    

    int line_num = 1;
    int count = 0;

    options.verbose = false;
    
    std::string test_name = std::format("{:=>6} {:>4} {:15} {:=>6}", '=', test.op, rulemap[static_cast<RULE_TYPE>(test.mode)], '=');
    line = std::format("; {}\n", test_name);
    src_mgr.source[{fileid, line_num}] = line;
    source_code += (line + "\n");
    line_num++;

    std::string orgline = std::format("    * = 0");
    line = std::format("{}\n", orgline);
    src_mgr.source[{fileid, line_num}] = line;
    source_code += (line + "\n");
    line_num++;

    switch (test.mode) {
        case RULE_TYPE::Op_Implied:
            expected_output.push_back(test.expected);

            line = std::format("    {}", test.op);
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;
            break;
            
        case RULE_TYPE::Op_Immediate:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_immediate);

                line = std::format("    {} #${:02X}", test.op, opr_immediate);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_immediate++;
                count++;
            }
            break;
        
      case RULE_TYPE::Op_Absolute:
        while (count < max) {
            expected_output.push_back(test.expected);
            expected_output.push_back(opr_absolute & 0xFF);
            expected_output.push_back((opr_absolute >> 8) & 0xFF);

            line = std::format("    {} ${:04X}", test.op, opr_absolute);
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;
            opr_absolute++;
            if (opr_absolute > abs_max) {
                opr_absolute = abs_min;
            }
            if (opr_absolute < abs_min) {
                opr_absolute = abs_min;
            }
            count++;
        }
        break;
        
        case RULE_TYPE::Op_ZeroPage:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_zeropage);

                line = std::format("    {} ${:02X}", test.op, opr_zeropage);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_zeropage++;
                count++;
            }
            break;
        
        case RULE_TYPE::Op_AbsoluteX:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_absolutex & 0xFF);
                expected_output.push_back((opr_absolutex >> 8) & 0xFF);

                line = std::format("    {} ${:04X},X", test.op, opr_absolutex);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_absolutex++;
                if (opr_absolutex > abs_max) {
                    opr_absolutex = abs_min;
                }
                if (opr_absolutex < abs_min) {
                    opr_absolutex = abs_min;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_ZeroPageX:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_zeropagex);

                line = std::format("    {} ${:02X},X", test.op, opr_zeropagex);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_zeropagex++;
                count++;
            }
            break;

        case RULE_TYPE::Op_AbsoluteY:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_absolutey & 0xFF);
                expected_output.push_back((opr_absolutey >> 8) & 0xFF);

                line = std::format("    {} ${:04X},Y", test.op, opr_absolutey);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_absolutey++;
                if (opr_absolutey > abs_max) {
                    opr_absolutey = abs_min;
                }
                if (opr_absolutey < abs_min) {
                    opr_absolutey = abs_min;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_ZeroPageY:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_zeropagey);

                line = std::format("    {} ${:02X},Y", test.op, opr_zeropagey);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_zeropagey++;
                count++;
            }
            break;
     
        case RULE_TYPE::Op_Indirect:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_indirect & 0xFF);
                expected_output.push_back((opr_indirect >> 8) & 0xFF);

                line = std::format("    {} (${:04X})", test.op, opr_indirect);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_indirect++;
                if (opr_indirect > abs_max) {
                    opr_indirect = abs_min;
                }
                if (opr_indirect < abs_min) {
                    opr_indirect = abs_min;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_IndirectX:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_indirectx);

                line = std::format("    {} (${:04X},X)", test.op, opr_indirectx);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_indirectx++;
                if (opr_indirectx > abs_max) {
                    opr_indirectx = abs_min;
                }
                if (opr_indirectx < abs_min) {
                    opr_indirectx = abs_min;
                }
                count++;
            }
            break;
            
         case RULE_TYPE::Op_IndirectY:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_indirecty);

                line = std::format("    {} (${:04X}),Y", test.op, opr_indirecty);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_indirecty++;
                if (opr_indirecty > abs_max) {
                    opr_indirecty = abs_min;
                }
                if (opr_indirecty < abs_min) {
                    opr_indirecty = abs_min;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_Accumulator:
            expected_output.push_back(test.expected);

            line = std::format("    {} A", test.op);
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;
            break;
     
        case RULE_TYPE::Op_Relative:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_relative -rel_offset);

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
    if (expected_output.size() >= 0xFFFF) {
        throw std::runtime_error(std::format("PC exceeded. Lower maxiteration."));
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
            if (negative) {
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
                        std::cout << "expected:\n";
                        for (auto& eb: expected_output) {
                            std::cout << std::format(" ${:02X} ", eb);
                        }
                        std::cout << "\n";
                        std::cout << "actual:\n";
                        for (auto& eb: assembler.binary_output) {
                            std::cout << std::format(" ${:02X} ", eb);
                        }
                        std::cout << "\n";
                    }
                }
            }
        }
        catch (std::exception& ex) {
            pass = negative;         
        }
        if (!pass) {
            std::cout << std::format("TEST {} {} {} {}\n", test_num, test_name, (negative ? "negative" : ""), "FAIL");
            
            std::cout << source_code;
            exit(0);
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
                    negative_opcode_tests.push_back({op, mode, 0});
                }
                else {
                    auto [opcode, _] = modeIt->second;
                    
                    positive_opcode_tests.push_back({op, mode, opcode});
                }
            }
        }
    }
}


int Opcode_test::test(int max_iterations)
{
    std::vector<OP_TEST> positive_opcode_tests;
    std::vector<OP_TEST> negative_opcode_tests;

    build_opcode_tests(positive_opcode_tests, negative_opcode_tests);

    
    for (auto& test: positive_opcode_tests) {
        if (op_test(test, max_iterations, false)) {
            passed++;
        }
        else {
            failed++;
        }
    }
    
    for (auto& test: negative_opcode_tests) {
        if (op_test(test, max_iterations, true)) {
            passed++;
        }
        else {
            failed++;
        }
    }
    
    return failed == 0;
}