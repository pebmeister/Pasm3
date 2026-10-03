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

Label_test::Test Label_test::create_anon_labels_test()
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

    // Anonymous label testing (+, ++ for forward; -, -- for backward)
    add_line("    jmp +");
    add_line("-");
    add_line("    nop");
    add_line("    nop");
    add_line("-");
    add_line("    .word -");
    add_line("    .word --");
    add_line("    jmp +");
    add_line("+");
    add_line("    nop");
    add_line("+");
    add_line("    .word +");
    add_line("    .word ++");
    add_line("+");
    add_line("    nop");
    add_line("+");
    add_line("    rts");

    // Expected Memory Layout & Address Resolution:
    // $1000: jmp +      -> Jumps 1 forward to 1st '+' ($100C)      [4C 0C 10]
    // $1003: -          -> 2nd backward label relative to $1007
    // $1003: nop        -> $1003                                    [EA]
    // $1004: nop        -> $1004                                    [EA]
    // $1005: -          -> 1st backward label relative to $1005
    // $1005: .word -    -> Resolves 1 back to '-' ($1005)           [05 10]
    // $1007: .word --   -> Resolves 2 back to '--' ($1003)          [03 10]
    // $1009: jmp +      -> Jumps 1 forward to '+' ($100C)          [4C 0C 10]
    // $100C: +          -> 1st forward label relative to $1009
    // $100C: nop        -> $100C                                    [EA]
    // $100D: +          -> Label at $100D
    // $100D: .word +    -> Resolves 1 forward to '+' ($1011)        [11 10]
    // $100F: .word ++   -> Resolves 2 forward to '++' ($1012)       [12 10]
    // $1011: +          -> Label at $1011
    // $1011: nop        -> $1011                                    [EA]
    // $1012: +          -> Label at $1012
    // $1012: rts        -> $1012                                    [60]

    std::vector<uint8_t> expected_output = {
        0x4C, 0x0C, 0x10, // jmp $100C
        0xEA,             // nop
        0xEA,             // nop
        0x05, 0x10,       // .word $1005
        0x03, 0x10,       // .word $1003
        0x4C, 0x0C, 0x10, // jmp $100C
        0xEA,             // nop
        0x11, 0x10,       // .word $1011
        0x12, 0x10,       // .word $1012
        0xEA,             // nop
        0x60              // rts
    };

    return Test(src_mgr, source_code, expected_output, false);
}

