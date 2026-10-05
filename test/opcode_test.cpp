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
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"
#include "ANSI_esc.h"
#include "test_runner.h"

#include "opcode_test.h"

Opcode_test::Test Opcode_test::make_unit_test(OP_TEST& test, int max)
{
    Options options;
    options.verbose = false;

    SourceManager src_mgr;
    std::vector<uint8_t> expected_output;
    std::string line;

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
    
    return Test(src_mgr, source_code, expected_output, test.negative_test);
}
