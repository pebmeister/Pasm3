/**
 * @file test_main.cpp
 * @brief Main entry point for the PASM 6502 multi-pass assembler CLI tool.
 * @author Paul Baxter
 * @details Handles command-line option parsing, source loading, tokenization,
 *          parsing, multi-pass binary assembly, and binary/PRG output generation.
 */

#include <chrono>
#include <exception>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <filesystem>
#include <format> // <-- Added for std::format
#include <cctype>

#define GEN_RULEMAP
#include "ruletype.h"
#undef GEN_RULEMAP

#define GEN_TOKMAP
#include "tokenkind.h"
#undef GEN_TOKMAP

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


struct OP_TEST {
    std::string op;
    int mode;
    uint8_t expected;
};

int op_test(OP_TEST& test, int depth, bool negative);
int test_num = 0;

int op_test(OP_TEST& test, int max, bool negative)
{
    Options options;
    SourceManager src_mgr;
    PasmTokenizer tokenizer;
    std::vector<uint8_t> expected_output;
    std::unordered_map<std::string, MacroDef> macros_;
    std::vector<AnonymousLabel> anonymous_labels;
    
    std::string line;
    std::string source_code;
    
    constexpr int fileid = 0;
    int line_num = 1;
    static uint8_t opr_immediate = 0;
    static uint8_t opr_zeropage = 0;
    static uint8_t opr_zeropagex = 0;
    static uint8_t opr_zeropagey = 0;
    static uint8_t opr_indirectx = 0;
    static uint8_t opr_indirecty = 0;
    static int16_t opr_relative = -128 + 2;
    static int16_t opr_zprelative = -128 + 3;
    static uint8_t opr_zprel_addr = 0;
    static uint16_t opr_absolute = 0x0100;
    static uint16_t opr_absolutex = 0x0100;
    static uint16_t opr_absolutey = 0x0100;
    static uint16_t opr_indirect = 0x0100;
    int count = 0;

    options.verbose = false;
    
    std::string test_name = std::format("{:=>6} {:>4} {:15} {:=>6}", '=', test.op, rulemap[static_cast<RULE_TYPE>(test.mode)], '=');
    line = std::format("; {}\n", test_name);
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
            if (opr_absolute < 0x0100) {
                opr_absolute = 0x0100;
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
                if (opr_absolutex < 0x0100) {
                    opr_absolutex = 0x0100;
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
                if (opr_absolutey < 0x0100) {
                    opr_absolutey = 0x0100;
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
                if (opr_indirect < 0x0100) {
                    opr_indirect = 0x0100;
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
                expected_output.push_back(opr_relative -2);

                line = std::format("    {} * + ({})", test.op, opr_relative);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_relative++;
                if (opr_relative  >= 127) {
                    opr_relative = -128 + 2;
                }
                count++;
            }
            break;

        case RULE_TYPE::Op_ZeroPageRelative:
            while (count < max) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr_zprel_addr);
                expected_output.push_back(opr_zprelative - 3);

                line = std::format("    {} ${:02X}, * + ({})", test.op, opr_zprel_addr, opr_zprelative);
                src_mgr.source[{fileid, line_num}] = line;
                source_code += (line + "\n");
                line_num++;
                opr_zprel_addr++;
                opr_zprelative++;
                if (opr_zprelative >= 127) {
                    opr_zprelative = -128 + 3;
                }
                count++;
            }
            break;
    
         default:
            break;
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
            std::string pass_str = pass ? "PASS" : "FAIL";
            std::cout << std::format("TEST {} {} {} {}\n", test_num, test_name, (negative ? "negative" : ""), pass_str);
                std::cout << source_code;
        }
    }
    return pass;
}

void build_opcode_tests(std::vector<OP_TEST>& positive_opcode_tests, std::vector<OP_TEST>& negative_opcode_tests)
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

int main(int argc, char* argv[])
{    
    std::vector<OP_TEST> positive_opcode_tests;
    std::vector<OP_TEST> negative_opcode_tests;

    if (argc != 1) {
        build_opcode_tests(positive_opcode_tests, negative_opcode_tests);
    }
    auto arg_num = 1;
    while (arg_num < argc) {
        std::string arg = std::string(argv[arg_num]);
        
        if (arg == "-opcode") {
            build_opcode_tests(positive_opcode_tests, negative_opcode_tests);
        }
        else if (arg == "--all") {
            build_opcode_tests(positive_opcode_tests, negative_opcode_tests);
        }
        arg_num++;
    }

    for (auto& test: positive_opcode_tests) {
        op_test(test, 20, false);
    }
    
    for (auto& test: negative_opcode_tests) {
        op_test(test, 20, true);
    }
    return 0;
}