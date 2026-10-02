/**
 * @file opcode_test.cpp
 * @author Paul Baxter
 * @brief Implements automated unit testing routines for 6502/65C02 opcodes and addressing modes in Pasm3.
 * @version 1.0
 * @date 2026-09-28
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

/**
 * @brief Executes an assembly and validation test for a single opcode and addressing mode combination.
 * 
 * Constructs synthesized source code lines for the specified test rule, tokenizes and parses them, 
 * runs the multi-pass assembler, and compares the resulting binary output against expected values 
 * or validates expected error behavior for negative tests.
 * 
 * @param test Reference to the OP_TEST structure defining the opcode, rule type, expected bytecode, and flags.
 * @param max Maximum number of operand iterations/loops to perform during test code generation.
 * @return int Returns true (1) if the test passes successfully, or false (0) if a mismatch or unexpected exception occurs.
 */
int Opcode_test::op_test(OP_TEST& test, int max)
{
    Options options;
    options.verbose = false;

    SourceManager src_mgr;
    PasmTokenizer tokenizer;
    std::vector<uint8_t> expected_output;
    std::string line;
    std::string source_code;
    std::stringstream ss;

    constexpr int org = 0x1000;
    int line_num = 1;
    int count = 0;
    
    // helper to add a line of source code
    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line(std::format("; {:=>6} {:>4} {:15} {:=>6}", '=', test.op, rulemap[static_cast<RULE_TYPE>(test.mode)], '='));    
    add_line();
    add_line(std::format("    * = {}", org));
    add_line();

    // Helper for single-instruction modes (Implied, Accumulator)
    auto emit_single = [&](std::string_view suffix = "") {
        expected_output.push_back(test.expected);
        add_line(suffix.empty() ? std::format("    {}", test.op) : std::format("    {} {}", test.op, suffix));
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

            add_line(std::format("    {} {}", test.op, format_fn(opr_ref)));
            
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

                add_line(std::format("    {} * + ({})", test.op, opr_relative));
                
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

                add_line(std::format("    {} ${:02X}, * + ({})", test.op, opr_zprel_addr, opr_zprelative));

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
            AssemblerParser parser(tokens, options, src_mgr);
            auto statements = parser.ParseProgram(tokenizer);
            MultiPassAssembler assembler(options);
            assembler.Assemble(statements, src_mgr);
            
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
                            ss << std::format(" ${:02X} ", eb);
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
            error = ss.str();
            source = source_code;
        }
    }
    return pass;
}

/**
 * @brief Populates positive and negative test case collections for all supported 6502/65C02 opcodes.
 * 
 * Iterates through the comprehensive table of instructions—including standard ALU, branch, bit 
 * manipulation, stack, and undocumented/illegal opcodes—and builds corresponding test vectors 
 * categorized by valid and invalid addressing modes.
 * 
 * @param positive_opcode_tests Vector to store valid opcode/addressing-mode test configurations.
 * @param negative_opcode_tests Vector to store invalid/unsupported addressing-mode test configurations.
 */
void Opcode_test::build_opcode_tests(std::vector<OP_TEST>& positive_opcode_tests, std::vector<OP_TEST>& negative_opcode_tests)
{
    for (auto&[_, info]: opcodeDict) {
        auto& op = info.mnemonic;
        for (int mode = RULE_TYPE::Op_Implied; mode <= RULE_TYPE::Op_ZeroPageRelative; ++mode) {
            auto modeIt = info.mode_to_opcode.find(static_cast<RULE_TYPE>(mode));
            if (modeIt == info.mode_to_opcode.end()) {
                negative_opcode_tests.push_back({op, mode, 0, true});
            }
            else {
                auto [opcode, _] = modeIt->second;
                
                positive_opcode_tests.push_back({op, mode, opcode, false});
            }
        }
    }
}

/**
 * @brief Executes the full opcode test suite and reports live progress to the console.
 * 
 * Runs both positive and negative test suites, updating the pass/fail counters and rendering 
 * ANSI-escaped progress information at the designated console position.
 * 
 * @param max_iterations Maximum operand iterations per addressing mode test.
 * @param line Terminal row coordinate for live output rendering.
 * @param col Terminal column coordinate for live output rendering.
 * @param exit_on_fail If true, immediately terminates execution upon encountering a test failure.
 * @return int Total number of failed test cases encountered.
 */
int Opcode_test::test(int max_iterations, int col, bool exit_on_fail)
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
            if (failed) {
                std::cout << std::format("{}{} {}PASSED: {:4} {}FAILED: {}", es.column(col), es.ERASE_CURSOR_EOL, 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed, es.gr(es.BRIGHT_RED_FOREGROUND), failed);
                    
                if (exit_on_fail) {
                    return failed;
                }
            } else {
                std::cout << std::format("{}{} {}PASSED: {:4} of {} ", es.column(col), es.ERASE_CURSOR_EOL, 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed, total_tests);
            }
        }
    }
    return failed;
}