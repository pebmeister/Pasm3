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

int op_test(OP_TEST& test, int depth);

int op_test(OP_TEST& test, int depth)
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
    int lineNo = 1;
    uint16_t opr;

    if (depth <= 0) depth = 1;

    switch (test.mode) {
        case RULE_TYPE::Op_Implied:
            expected_output.push_back(test.expected);
            line = std::format("    {}", test.op);
            src_mgr.source[{fileid, lineNo}] = line;
            source_code += (line + "\n");   
            break;
            
        case RULE_TYPE::Op_Immediate:
            opr = 0;
            while (opr <= 0xFF) {
                expected_output.push_back(test.expected);
                expected_output.push_back(opr);

                line = std::format("    {} #${:02X}", test.op, opr);
                src_mgr.source[{fileid, lineNo}] = line;
                source_code += (line + "\n");
                lineNo++;
                opr += depth;
            }
            break;
            
         default:
            break;
    }
    if (source_code.length() > 0) {

        std::cout << 
            std::format("; {:=>6} {:>4} {:12} {:=>6}\n", '=', test.op, rulemap[static_cast<RULE_TYPE>(test.mode)], '=');
        
        auto tokens = tokenizer.tokenize(source_code, fileid);
        AssemblerParser parser(tokens, options);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);

    }
    return 0;
}

int main(int argc, char* argv[])
{    
    if (argc != 1) {
        return 0;
    }
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
     
    std::vector<OP_TEST> positive_opcode_tests;
    std::vector<OP_TEST> negative_opcode_tests;
    
    for (auto& op : ops) {
        auto info  = FindOpCodeInfo(op);
        if (info != NULL) {
            
            for (int mode = RULE_TYPE::Op_Implied; mode <= RULE_TYPE::Op_ZeroPageRelative; ++mode) {
                if (info->is_illegal) continue;
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
    
    for (auto& test: positive_opcode_tests) {
        op_test(test, 1);
    }
    
    return 0;
}