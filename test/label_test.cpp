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
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    constexpr uint8_t JMP_OPCODE = 0x4C; // 6502 absolute JMP opcode
    auto org = 0x1000;
    auto pc = org;
    auto target_count = max;

    // ------------------------------------------------------------------
    // 1. Backward Anonymous Labels (-) Test
    // ------------------------------------------------------------------

    add_line(std::format("    * = {}", org));

    // Store created target addresses in order (0x1000, 0x1002, 0x1004, ...)
    std::vector<uint16_t> backward_targets;

    auto count = 0;
    while (count < target_count) {
        auto addr = pc;
        backward_targets.push_back(addr);
        add_line(std::format("{:1}    {} ${:04X}", "-", ".word", addr));
        
        expected_output.push_back(static_cast<uint8_t>(addr & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((addr >> 8) & 0xFF));
        if (org + expected_output.size() >= 0xFFFF) {
            throw std::runtime_error(std::format("PC exceeded. Lower max iteration."));
        }
        
        count++;
        pc += 2;
    }

    // Jumps targeting backward labels:
    // '-'   targets backward_targets[last]  (most recent)
    // '--'  targets backward_targets[last - 1]
    count = 0;
    while (count < target_count) {
        add_line(std::format("    {} {}", "jmp", std::string(count + 1, '-')));

        uint16_t target_addr = backward_targets[backward_targets.size() - 1 - count];

        expected_output.push_back(JMP_OPCODE);
        expected_output.push_back(static_cast<uint8_t>(target_addr & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((target_addr >> 8) & 0xFF));
        if (org + expected_output.size() >= 0xFFFF) {
            throw std::runtime_error(std::format("PC exceeded. Lower max iteration."));
        }

        pc += 3;
        count++;
    }

    // ------------------------------------------------------------------
    // 2. Forward Anonymous Labels (+) Test
    // ------------------------------------------------------------------

    // Pre-calculate target addresses for upcoming forward labels
    // The forward labels will start at current 'pc' plus total bytes of all forward jmp instructions
    uint16_t forward_labels_start_pc = pc + (target_count * 3);
    std::vector<uint16_t> forward_targets;
    for (int i = 0; i < target_count; ++i) {
        forward_targets.push_back(forward_labels_start_pc + (i * 2));
    }

    // Jumps targeting forward labels:
    // '+'   targets forward_targets[0] (first upcoming)
    // '++'  targets forward_targets[1]
    count = 0;
    while (count < target_count) {
        add_line(std::format("    {} {}", "jmp", std::string(count + 1, '+')));

        uint16_t target_addr = forward_targets[count];

        expected_output.push_back(JMP_OPCODE);
        expected_output.push_back(static_cast<uint8_t>(target_addr & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((target_addr >> 8) & 0xFF));
        if (org + expected_output.size() >= 0xFFFF) {
            throw std::runtime_error(std::format("PC exceeded. Lower max iteration."));
        }

        pc += 3;
        count++;
    }

    // Generate the forward target data (.word pc)
    count = 0;
    while (count < target_count) {
        add_line(std::format("{:1}    {} ${:04X}", "+", ".word", pc));

        expected_output.push_back(static_cast<uint8_t>(pc & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((pc >> 8) & 0xFF));

        if (org + expected_output.size() >= 0xFFFF) {
            throw std::runtime_error(std::format("PC exceeded. Lower max iteration."));
        }

        pc += 2;
        count++;
    }

    return Test(src_mgr, source_code, expected_output, false);
}

Label_test::Test Label_test::create_local_label_test()
{
    constexpr int fileid = 0;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;
    
    src_mgr.files.push_back("Label_test");

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    constexpr uint8_t JMP_OPCODE = 0x4C; // 6502 JMP absolute
    constexpr uint8_t NOP_OPCODE = 0xEA;
    uint16_t org = 0x1000;
    uint16_t pc = org;

    add_line(std::format("    * = ${:04X}", org));

    // ------------------------------------------------------------------
    // Parent Scope 1: parent_1
    // ------------------------------------------------------------------
    add_line("parent_1:");
    
    // Local label @loop inside parent_1 scope
    uint16_t p1_loop_addr = pc;
    add_line("@loop");
    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // Backward local jump to @loop (resolves to parent_1@loop)
    add_line("    jmp @loop");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(p1_loop_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((p1_loop_addr >> 8) & 0xFF));
    pc += 3;

    // Forward local jump to @exit (resolves to parent_1@exit)
    uint16_t p1_exit_addr = pc + 3 + 1; // jmp size (3) + nop size (1)
    add_line("    jmp @exit");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(p1_exit_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((p1_exit_addr >> 8) & 0xFF));
    pc += 3;

    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    add_line("@exit");
    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // ------------------------------------------------------------------
    // Parent Scope 2: parent_2 (Resets local scope)
    // ------------------------------------------------------------------
    add_line("parent_2:");

    // Re-use same local label name @loop inside parent_2 scope
    uint16_t p2_loop_addr = pc;
    add_line("@loop");
    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // Local jump to @loop (must resolve to parent_2@loop)
    add_line("    jmp @loop");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(p2_loop_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((p2_loop_addr >> 8) & 0xFF));
    pc += 3;

    // Fully-qualified cross-scope jump to parent_1's local label
    add_line("    jmp parent_1@loop");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(p1_loop_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((p1_loop_addr >> 8) & 0xFF));
    pc += 3;

    return Test(src_mgr, source_code, expected_output, false);
}

Label_test::Test Label_test::create_combined_label_test()
{
    constexpr int fileid = 0;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    constexpr uint8_t JMP_OPCODE = 0x4C;
    constexpr uint8_t NOP_OPCODE = 0xEA;
    uint16_t org = 0x2000;
    uint16_t pc = org;

    add_line(std::format("    * = ${:04X}", org));

    // Global Label: entry_point (Establishes scope 'entry_point')
    uint16_t entry_addr = pc;
    add_line("entry_point:");

    // Anonymous Backward Target (-)
    uint16_t anon_back_1 = pc;
    add_line("-   nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // Local Label @init under entry_point scope
    uint16_t init_addr = pc;
    add_line("@init");
    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // 1. Anonymous backward jump (-)
    add_line("    jmp -");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(anon_back_1 & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((anon_back_1 >> 8) & 0xFF));
    pc += 3;

    // 2. Forward Anonymous jump (+)
    uint16_t anon_forward_1 = pc + 3 + 3; // After jmp + and jmp @init
    add_line("    jmp +");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(anon_forward_1 & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((anon_forward_1 >> 8) & 0xFF));
    pc += 3;

    // 3. Backward Local jump (@init) -> entry_point@init
    add_line("    jmp @init");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(init_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((init_addr >> 8) & 0xFF));
    pc += 3;

    // Target for Anonymous Jump 2 (+)
    add_line("+   nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // ------------------------------------------------------------------
    // New Global Scope: process_data (Resets scope to 'process_data')
    // ------------------------------------------------------------------
    add_line("process_data:");

    // Local Label @init under process_data (distinct from entry_point@init)
    uint16_t process_init_addr = pc;
    add_line("@init");
    add_line("    nop");
    expected_output.push_back(NOP_OPCODE);
    pc += 1;

    // 4. Jump to Global entry_point
    add_line("    jmp entry_point");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(entry_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((entry_addr >> 8) & 0xFF));
    pc += 3;

    // 5. Jump to local @init in current scope (process_data@init)
    add_line("    jmp @init");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(process_init_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((process_init_addr >> 8) & 0xFF));
    pc += 3;

    // 6. Jump to explicit previous global scope local (entry_point@init)
    add_line("    jmp entry_point@init");
    expected_output.push_back(JMP_OPCODE);
    expected_output.push_back(static_cast<uint8_t>(init_addr & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((init_addr >> 8) & 0xFF));
    pc += 3;

    return Test(src_mgr, source_code, expected_output, false);
}