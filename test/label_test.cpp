#include <format>
#include <string>

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

#include "label_test.h"

int Label_test::test(int col)
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;
    std::stringstream ss;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line(std::format("    * = {}", org));

    constexpr size_t num_global_labels = 10;
    constexpr size_t bytes_per_labels = 2;

    std::vector<uint8_t> expected_output;
    
    // The second block starts right after the first block of .word directives
    uint16_t second_block_start = static_cast<uint16_t>(org + num_global_labels * bytes_per_labels);
    
    uint16_t first_loop_addr = second_block_start;
    for (size_t n = 0; n < num_global_labels; ++n) {
        add_line(std::format("    .word Label{:04X}", n));
        
        uint8_t lo = static_cast<uint8_t>(first_loop_addr & 0xFF);
        uint8_t hi = static_cast<uint8_t>((first_loop_addr >> 8) & 0xFF);
        expected_output.push_back(lo);
        expected_output.push_back(hi);
        first_loop_addr += 2;        
    }
    
    uint16_t second_loop_addr = second_block_start;
    for (size_t n = 0; n < num_global_labels; ++n) {
        add_line(std::format("Label{:04X}    .word ${:04X}", n, second_loop_addr));

        uint8_t lo = static_cast<uint8_t>(second_loop_addr & 0xFF);
        uint8_t hi = static_cast<uint8_t>((second_loop_addr >> 8) & 0xFF);
        expected_output.push_back(lo);
        expected_output.push_back(hi);
        second_loop_addr += 2;        
    }

    int passed = 1;
    int failed = 0;
    try {
        PasmTokenizer tokenizer;
        Options options;
        options.verbose = false;
        std::unordered_map<std::string, MacroDef> macros_;
        std::vector<AnonymousLabel> anonymous_labels;    

        auto tokens = tokenizer.tokenize(source_code, fileid);
        AssemblerParser parser(tokens, options);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);
        MultiPassAssembler assembler(options);
        assembler.Assemble(statements, anonymous_labels, src_mgr);

        if (passed) {
            passed = expected_output == assembler.binary_output;

            if (!passed) {
                failed += 1;
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
                error = ss.str();
                std::cout << error;
            }
        }
        if (passed) {
            std::cout << std::format("{}{} {}PASSED: {:4}", es.column(col), es.ERASE_CURSOR_EOL, 
                es.gr(es.BRIGHT_GREEN_FOREGROUND), passed);
        }
        else {
            std::cout << std::format("{}{} {}PASSED: {:4} {}FAILED: {}", es.column(col), es.ERASE_CURSOR_EOL, 
                es.gr(es.BRIGHT_GREEN_FOREGROUND), passed, es.gr(es.BRIGHT_RED_FOREGROUND), failed);
        }

    }
    catch (std::exception& ex) {
        passed = 0;         
    }

    return passed;
}