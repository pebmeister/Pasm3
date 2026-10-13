#include <sstream>
#include <format>
#include <string>
#include <vector>
#include <stdexcept>

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

#include "control_flow_test.h"

Control_flow_test::Test Control_flow_test::create_basic_if_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_basic_if_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.var VAL = 5", Tab(0)));
    add_line(std::format("{}.if VAL == 5", Tab(0)));
    add_line(std::format("{}RES = 42", Tab(1)));
    add_line(std::format("{}.endif", Tab(0)));
    add_line(std::format("{}.word RES", Tab(0)));

    uint16_t val = 42;
    expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    if (org + expected_output.size() >= 0xFFFF) {
        throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
    }

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Control_flow_test::Test Control_flow_test::create_if_else_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_if_else_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.var VAL = 10", Tab(0)));
    add_line(std::format("{}.if VAL < 5", Tab(0)));
    add_line(std::format("{}RES = 1", Tab(1)));
    add_line(std::format("{}.else", Tab(0)));
    add_line(std::format("{}RES = 2", Tab(1)));
    add_line(std::format("{}.endif", Tab(0)));
    add_line(std::format("{}.word RES", Tab(0)));

    uint16_t val = 2; // VAL = 10 is not < 5, so RES takes the .else branch (2)
    expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    if (org + expected_output.size() >= 0xFFFF) {
        throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
    }

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Control_flow_test::Test Control_flow_test::create_nested_if_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_nested_if_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.var A = 2", Tab(0)));
    add_line(std::format("{}.var B = 3", Tab(0)));
    add_line(std::format("{}.if A == 2", Tab(0)));
    add_line(std::format("{}.if B == 3", Tab(1)));
    add_line(std::format("{}RES = 100", Tab(2)));
    add_line(std::format("{}.else", Tab(1)));
    add_line(std::format("{}RES = 200", Tab(2)));
    add_line(std::format("{}.endif", Tab(1)));
    add_line(std::format("{}.else", Tab(0)));
    add_line(std::format("{}RES = 300", Tab(1)));
    add_line(std::format("{}.endif", Tab(0)));
    add_line(std::format("{}.word RES", Tab(0)));

    uint16_t val = 100; // A == 2 and B == 3 are both true -> 100
    expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
    expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    if (org + expected_output.size() >= 0xFFFF) {
        throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
    }

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, expected_output, false);
}

Control_flow_test::Test Control_flow_test::create_orphaned_else_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_orphaned_else_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.else", Tab(0))); // Invalid without preceding .if

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, {}, true);
}

Control_flow_test::Test Control_flow_test::create_orphaned_endif_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_orphaned_endif_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.endif", Tab(0))); // Invalid without preceding .if

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, {}, true);
}

Control_flow_test::Test Control_flow_test::create_unmatched_if_test()
{
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    Line_Adder add_line(src_mgr, "create_unmatched_if_test", org);
    std::vector<uint8_t> expected_output;

    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.if VAL == 1", Tab(0)));
    add_line(std::format("{}RES = 10", Tab(1)));
    // Missing matching .endif

    add_line.GetSource(source_code);
    return Test(src_mgr, source_code, {}, true);
}