#include <sstream>
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
#include "ANSI_esc.h"

#include "label_test.h"


Label_test::Test Label_test::create_foward_labels_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    add_line(std::format("    * = {}", org));
    
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
    return Test(src_mgr, source_code, expected_output, false);    
}

Label_test::Test Label_test::create_global_labels_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    add_line(std::format("    * = {}", org));
    
    constexpr size_t num_global_labels = 10000;
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

    return Test(src_mgr, source_code, expected_output, false);
}
