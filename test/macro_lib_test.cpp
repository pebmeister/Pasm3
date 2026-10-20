
#include <sstream>
#include <format>
#include <string>

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
#include "macro_lib_test.h"

Macro_lib_test::Test Macro_lib_test::create_macro_PUSH16_test(int max)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_macro_PUSH16_test", org);
    std::vector<uint8_t> expected_output;

    add_line(";********************************************");
    add_line(";*                                          *");
    add_line(";* PUSH16                                   *");
    add_line(";*                                          *");
    add_line(";*  push 16 bit value                       *");
    add_line(";*                                          *");
    add_line(";*  destructs a                             *");
    add_line(";*                                          *");
    add_line(";********************************************");
    add_line(".macro PUSH16");
    add_line("  lda \\1");
    add_line("  pha");
    add_line("  lda \\1 + 1");
    add_line("  pha");
    add_line(".endm");
    add_line("");
    add_line();

    auto gen_bytes = [](uint16_t address) -> std::vector<uint8_t> {
        std::vector<uint8_t> bytes;

        // First instruction (lda \1)
        if (address > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0xAD));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
            bytes.push_back(static_cast<uint8_t>((address >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0xA5));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
        }
        bytes.push_back(static_cast<uint8_t>(0x48)); // pha

        // Second instruction (lda \1 + 1)
        uint16_t addr_high = address + 1;
        if (addr_high > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0xAD));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
            bytes.push_back(static_cast<uint8_t>((addr_high >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0xA5));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
        }
        bytes.push_back(static_cast<uint8_t>(0x48)); // pha

        return bytes;
    };

    // Dynamically generate macro test lines
    for (int sz = 0; sz <= max; sz++) {
        add_line(std::format("{}PUSH16 ${:04X}", Tab(1), sz));
        
        auto bytes = gen_bytes(static_cast<uint16_t>(sz));
        expected_output.insert(expected_output.end(), bytes.begin(), bytes.end());
    }

    std::string source_code;
    add_line.GetSource(source_code);
    
    Options options;
    options.verbose = false;

    return Test(src_mgr, source_code, expected_output, false, std::move(options));
}

Macro_lib_test::Test Macro_lib_test::create_macro_POP16_test(int max)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_macro_POP16_test", org);
    std::vector<uint8_t> expected_output;

    add_line(";********************************************");
    add_line(";*                                          *");
    add_line(";* POP16                                    *");
    add_line(";*                                          *");
    add_line(";*  pop 16 bit value                       *");
    add_line(";*                                          *");
    add_line(";*  destructs a                             *");
    add_line(";*                                          *");
    add_line(";********************************************");
    add_line(".macro POP16");
    add_line("  lda \\1");
    add_line("  pla");
    add_line("  lda \\1 + 1");
    add_line("  pla");
    add_line(".endm");
    add_line("");
    add_line();

    auto gen_bytes = [](uint16_t address) -> std::vector<uint8_t> {
        std::vector<uint8_t> bytes;

        // First instruction (lda \1)
        if (address > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0xAD));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
            bytes.push_back(static_cast<uint8_t>((address >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0xA5));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
        }
        bytes.push_back(static_cast<uint8_t>(0x68)); // pla

        // Second instruction (lda \1 + 1)
        uint16_t addr_high = address + 1;
        if (addr_high > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0xAD));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
            bytes.push_back(static_cast<uint8_t>((addr_high >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0xA5));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
        }
        bytes.push_back(static_cast<uint8_t>(0x68)); // pla

        return bytes;
    };

    // Dynamically generate macro test lines
    for (int sz = 0; sz <= max; sz++) {
        add_line(std::format("{}POP16 ${:04X}", Tab(1), sz));
        
        auto bytes = gen_bytes(static_cast<uint16_t>(sz));
        expected_output.insert(expected_output.end(), bytes.begin(), bytes.end());
    }

    std::string source_code;
    add_line.GetSource(source_code);
    
    Options options;
    options.verbose = false;

    return Test(src_mgr, source_code, expected_output, false, std::move(options));
}

Macro_lib_test::Test Macro_lib_test::create_macro_STORE8_test(int max)
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_macro_STORE8_test", org);
    std::vector<uint8_t> expected_output;

    add_line(";********************************************");
    add_line(";*                                          *");
    add_line(";* STORE8                                   *");
    add_line(";*                                          *");
    add_line(";*  store a variable                        *");
    add_line(";*                                          *");
    add_line(";*  \1  Source                              *");
    add_line(";*  \2  Destination                         *");
    add_line(";*                                          *");
    add_line(";*                                          *");
    add_line(";*  destroys a                              *");
    add_line(";*                                          *");
    add_line(";********************************************");
    add_line(".macro STORE8");
    add_line("  lda \\1");
    add_line("  sta \\2");
    add_line(".endm");
    add_line();

    auto gen_bytes = [](uint16_t address, uint16_t address2) -> std::vector<uint8_t> {
        std::vector<uint8_t> bytes;

        // First instruction (lda \1)
        if (address > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0xAD));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
            bytes.push_back(static_cast<uint8_t>((address >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0xA5));
            bytes.push_back(static_cast<uint8_t>(address & 0xFF));
        }

        // Second instruction (sta \2)
        uint16_t addr_high = address2;
        if (addr_high > 0xFF) {
            bytes.push_back(static_cast<uint8_t>(0x8D));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
            bytes.push_back(static_cast<uint8_t>((addr_high >> 8) & 0xFF));
        } else {
            bytes.push_back(static_cast<uint8_t>(0x85));
            bytes.push_back(static_cast<uint8_t>(addr_high & 0xFF));
        }

        return bytes;
    };

    // Dynamically generate macro test lines
    for (int sz = 1; sz <= max; sz++) {
        add_line(std::format("{}STORE8 ${:04X}, ${:04X}", Tab(1), sz - 1, sz));
        
        auto bytes = gen_bytes(static_cast<uint16_t>(sz -1), static_cast<uint16_t>(sz));
        expected_output.insert(expected_output.end(), bytes.begin(), bytes.end());
    }

    std::string source_code;
    add_line.GetSource(source_code);
    
    Options options;
    options.verbose = false;

    return Test(src_mgr, source_code, expected_output, false, std::move(options));
}
