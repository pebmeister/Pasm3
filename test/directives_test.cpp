#include "directives_test.h"

#include <sstream>
#include <format>
#include <string>
#include <vector>
#include <filesystem>
#include <fstream>

#include "optype.h"
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
#include "line_adder.h"

namespace fs = std::filesystem;

// Helper to write dummy binary test assets
void Directives_test::create_temp_bin_file(const std::string& filename, const std::vector<uint8_t>& bytes) {
    std::ofstream out(filename, std::ios::binary);
    if (out.is_open()) {
        out.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
    }
}

// Helper to remove dummy binary test assets
void Directives_test::remove_temp_file(const std::string& filename) {
    std::error_code ec;
    fs::remove(filename, ec);
}

Directives_test::Test Directives_test::create_incbin_full_file_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_incbin_full_file_test", org);

    add_line(std::format(".incbin \"{}\"", temp_files[0]));

    std::string source_code;
    add_line.GetSource(source_code);
    
    std::vector<uint8_t> expected_output(
        full_bytes.begin(), 
        full_bytes.end()
    );
    
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_incbin_offset_and_length_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_incbin_offset_and_length_test", org);

    // Skip 2 bytes (1 + 1), read 4 bytes (2 * 2)
    add_line(std::format(".incbin \"{}\", 1 + 1, 2 * 2", temp_files[1]));
    auto offset = 1 + 1;
    auto length = 2 * 2;
    std::vector<uint8_t> expected_output(
        dummy_bytes.begin() + offset, 
        dummy_bytes.begin() + offset + length
    );
    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_incbin_missing_file_negative_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_incbin_missing_file_negative_test", org);

    add_line(".incbin \"non_existent_binary_xyz123.bin\"");

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, {}, true);
}

// --- .ifdef / .ifndef Tests ---

Directives_test::Test Directives_test::create_ifdef_defined_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_ifdef_defined_test", org);

    add_line("FEATURE_ENABLED = 1");
    add_line(".ifdef FEATURE_ENABLED");
    add_line("    .byte $01, $02");
    add_line(".else");
    add_line("    .byte $FF, $FF");
    add_line(".endif");

    std::vector<uint8_t> expected_output = { 0x01, 0x02 };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_ifdef_undefined_else_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_ifdef_undefined_else_test", org);

    // FEATURE_ENABLED is NOT defined -> execute .else branch
    // Also tests that dead-code branch contains arbitrary invalid tokens without raising errors
    add_line(".ifdef UNSET_SYMBOL");
    add_line("    this is invalid code that should be skipped");
    add_line(".else");
    add_line("    .byte $AA, $BB");
    add_line(".endif");

    std::vector<uint8_t> expected_output = { 0xAA, 0xBB };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_ifndef_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_ifndef_test", org);

    add_line(".ifndef MISSING_SYMBOL");
    add_line("    .byte $10, $20");
    add_line(".endif");

    std::vector<uint8_t> expected_output = { 0x10, 0x20 };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_basic_header_test()
{
    constexpr int org = 0x0801;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_basic_header_test", org);

    add_line(".basic_hdr");
    add_line("    rts");

    // Standard 12-byte C64 BASIC stub for "10 SYS 2061" + assembly payload
    std::vector<uint8_t> expected_output = {
        0x0B, 0x08,             // Next BASIC line pointer ($080B)
        0x0A, 0x00,             // Line number 10
        0x9E,                   // BASIC SYS token
        0x32, 0x30, 0x36, 0x31, // ASCII "2061" ($080D)
        0x00,                   // BASIC line end terminator
        0x00, 0x00,             // BASIC program end terminator
        0x60                    // RTS opcode ($080D payload)
    };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_fill_directive_test(int max, uint8_t byte)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_fill_directive_test", org);

    // Fill 8 bytes with value $EA (NOP)
    add_line(std::format(".fill {}, {}", byte, max));

    // Expected output: max consecutive byte bytes
    std::vector<uint8_t> expected_output(max, byte);

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_ds_directive_test(int max)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_ds_directive_test", org);

    // Reserve max bytes of memory storage
    add_line(std::format(".ds {}", max));

    // Expected output: max zero-initialized memory bytes
    std::vector<uint8_t> expected_output(max, 0x00);

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_ds_move_pc_test(int max)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_ds_move_pc_test", org);

    add_line(std::format("Label"));

    add_line(std::format("    * = ${:04}", org / 2));
    add_line(std::format("    .ds {}", 1));
    add_line(std::format("    * = Label"));
    
    add_line(std::format("    .ds {}", max));
    
    // Expected output: max zero-initialized memory bytes
    std::vector<uint8_t> expected_output(max, 0x00);

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_byte_directive_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_byte_directive_test", org);

    // Test mixing string literals and numeric byte values
    add_line(".byte \"hello\", $00, $FF, 1 + 1");

    // Expected output: "hello" ASCII bytes + $00 + $FF + $02
    std::vector<uint8_t> expected_output = {
        'h', 'e', 'l', 'l', 'o',
        0x00,
        0xFF,
        0x02
    };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Directives_test::Test Directives_test::create_word_directive_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_word_directive_test", org);

    // Test 16-bit little-endian words ($1234 -> $34 $12)
    add_line(".word $1234, $1000 + $0001");

    // Expected output: 0x34, 0x12, 0x01, 0x10
    std::vector<uint8_t> expected_output = {
        0x34, 0x12,
        0x01, 0x10
    };

    std::string source_code;
    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}