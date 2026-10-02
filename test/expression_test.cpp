#include <iostream>
#include <sstream>
#include <format>
#include <string>
#include <vector>
#include <cstdint>

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

#include "ANSI_esc.h"
#include "expression_test.h"

int Expression_test::test(int col)
{    
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::stringstream ss;
    std::string error;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = ${:04X}", org));

    // Multi-pass expression chain testing (+, -, *, /) and forward label references
    add_line("cat = dog + 1");
    add_line("dog = cow * 2");
    add_line("cow = pig + 5");
    add_line("pig = horse / 2");
    add_line("horse = target_label - $0FE0");

    add_line("target_label:");
    add_line("    .word cat, dog, cow, pig, horse");

    // Expected Value Resolution:
    // target_label = $1000 (4096)
    // horse = $1000 - $0FE0 = 32  ($0020)
    // pig   = 32 / 2        = 16  ($0010)
    // cow   = 16 + 5        = 21  ($0015)
    // dog   = 21 * 2        = 42  ($002A)
    // cat   = 42 + 1        = 43  ($002B)
    std::vector<uint16_t> expected_words = { 43, 42, 21, 16, 32 };
    std::vector<uint8_t> expected_output;

    for (uint16_t val : expected_words) {
        expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    }

    int passed = 1;
    int failed = 0;

    try {
        PasmTokenizer tokenizer;
        Options options;
        options.verbose = false;
        std::vector<AnonymousLabel> anonymous_labels;

        auto tokens = tokenizer.tokenize(source_code, fileid);

        AssemblerParser parser(tokens, options, src_mgr);
        auto statements = parser.ParseProgram(tokenizer);
        MultiPassAssembler assembler(options, src_mgr);
        assembler.Assemble(statements, anonymous_labels);

        if (passed) {
            passed = (expected_output == assembler.binary_output);

            if (!passed) {
                failed += 1;
                ss << "expected:\n";
                for (auto& eb : expected_output) {
                    ss << std::format(" ${:02X} ", eb);
                }
                ss << "\nactual:\n";
                for (auto& eb : assembler.binary_output) {
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
        failed = 1;
        std::cout << std::format("{}{} {}PASSED: 0 {}FAILED: 1 ({})", es.column(col), es.ERASE_CURSOR_EOL, 
            es.gr(es.BRIGHT_GREEN_FOREGROUND), es.gr(es.BRIGHT_RED_FOREGROUND), ex.what());
    }

    return passed;
}
