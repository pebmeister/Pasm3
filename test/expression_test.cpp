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

#include "expression_test.h"

Expression_test::Test Expression_test::create_expression_operators_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));

    // --- Bitwise & Arithmetic ---
    add_line("res_add   = 100 + 25");      // 125  ($007D)
    add_line("res_sub   = 100 - 25");      // 75   ($004B)
    add_line("res_mul   = 12 * 8");        // 96   ($0060)
    add_line("res_div   = 100 / 4");       // 25   ($0019)
    add_line("res_mod   = 27 % 5");        // 2    ($0002)
    add_line("res_shl   = 1 << 5");        // 32   ($0020)
    add_line("res_shr   = 64 >> 2");       // 16   ($0010)
    add_line("res_and   = $00FF & $000F"); // 15   ($000F)
    add_line("res_or    = $00F0 | $000F"); // 255  ($00FF)
    add_line("res_xor   = $00AA ^ $0055"); // 255  ($00FF)

    // --- Logical Operators ---
    add_line("res_land1 = 1 && 1");        // 1    ($0001)
    add_line("res_land2 = 1 && 0");        // 0    ($0000)
    add_line("res_lor1  = 0 || 1");        // 1    ($0001)
    add_line("res_lor2  = 0 || 0");        // 0    ($0000)

    // --- Comparative Operators ---
    add_line("res_lt1   = 5 < 10");        // 1    ($0001)
    add_line("res_lt2   = 10 < 5");        // 0    ($0000)
    add_line("res_gt1   = 10 > 5");        // 1    ($0001)
    add_line("res_gt2   = 5 > 10");        // 0    ($0000)
    add_line("res_lte1  = 5 <= 5");        // 1    ($0001)
    add_line("res_lte2  = 6 <= 5");        // 0    ($0000)
    add_line("res_gte1  = 10 >= 10");      // 1    ($0001)
    add_line("res_gte2  = 9 >= 10");       // 0    ($0000)
    add_line("res_eq1   = 42 == 42");      // 1    ($0001)
    add_line("res_eq2   = 42 == 43");      // 0    ($0000)
    add_line("res_neq1  = 42 != 43");      // 1    ($0001)
    add_line("res_neq2  = 42 != 42");      // 0    ($0000)

    add_line("    .word res_add, res_sub, res_mul, res_div, res_mod");
    add_line("    .word res_shl, res_shr, res_and, res_or, res_xor");
    add_line("    .word res_land1, res_land2, res_lor1, res_lor2");
    add_line("    .word res_lt1, res_lt2, res_gt1, res_gt2");
    add_line("    .word res_lte1, res_lte2, res_gte1, res_gte2");
    add_line("    .word res_eq1, res_eq2, res_neq1, res_neq2");

    std::vector<uint16_t> expected_words = {
        // Arithmetic & Bitwise
        125, 75, 96, 25, 2, 32, 16, 15, 255, 255,
        // Logical
        1, 0, 1, 0,
        // Comparative
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0
    };

    std::vector<uint8_t> expected_output;
    expected_output.reserve(expected_words.size() * 2);

    for (uint16_t val : expected_words) {
        expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    }

    return Test(src_mgr, source_code, expected_output, false);
}

Expression_test::Test Expression_test::create_expression_order_of_operations_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));

    // --- Multiplication / Division vs Addition / Subtraction ---
    add_line("prec_mul_add1 = 2 + 5 * 5");       // 2 + 25 = 27        ($001B)
    add_line("prec_mul_add2 = (2 + 5) * 5");     // 7 * 5  = 35        ($0023)
    add_line("prec_div_sub1 = 100 - 20 / 4");   // 100 - 5 = 95       ($005F)
    add_line("prec_div_sub2 = (100 - 20) / 4"); // 80 / 4  = 20       ($0014)

    // --- Shift Operations vs Arithmetic ---
    add_line("prec_shift1   = 1 + 2 << 3");     // (1 + 2) << 3 = 24  ($0018)
    add_line("prec_shift2   = 1 << 2 + 3");     // 1 << (2 + 3) = 32  ($0020)

    // --- Bitwise Precedence (& over ^ and |) ---
    add_line("prec_bitwise1 = $0F | $F0 & $00"); // $0F | ($F0 & $00) = 15 ($000F)
    add_line("prec_bitwise2 = ($0F | $F0) & $00");// ($0F | $F0) & $00 = 0  ($0000)
    add_line("prec_bitwise3 = $FF ^ $0F & $33"); // $FF ^ ($0F & $33) = 252($00FC)

    // --- Relational Operations vs Arithmetic & Shift ---
    add_line("prec_rel1     = 5 + 5 == 10");     // (5 + 5) == 10 -> 1 ($0001)
    add_line("prec_rel2     = 1 << 2 == 4");     // (1 << 2) == 4 -> 1 ($0001)

    // --- Logical Precedence (&& over ||) ---
    add_line("prec_logical1 = 1 || 0 && 0");     // 1 || (0 && 0) -> 1 ($0001)
    add_line("prec_logical2 = (1 || 0) && 0");   // (1 || 0) && 0 -> 0 ($0000)

    // --- Complex Mixed Precedence ---
    add_line("prec_complex  = 10 + 2 * 3 == 16 && 5 << 1 + 1 == 20"); // 1 ($0001)

    add_line("    .word prec_mul_add1, prec_mul_add2, prec_div_sub1, prec_div_sub2");
    add_line("    .word prec_shift1, prec_shift2");
    add_line("    .word prec_bitwise1, prec_bitwise2, prec_bitwise3");
    add_line("    .word prec_rel1, prec_rel2");
    add_line("    .word prec_logical1, prec_logical2");
    add_line("    .word prec_complex");

    std::vector<uint16_t> expected_words = {
        // Mul/Div vs Add/Sub
        27, 35, 95, 20,
        // Shift vs Arithmetic
        24, 32,
        // Bitwise
        15, 0, 252,
        // Relational
        1, 1,
        // Logical
        1, 0,
        // Complex
        1
    };

    std::vector<uint8_t> expected_output;
    expected_output.reserve(expected_words.size() * 2);

    for (uint16_t val : expected_words) {
        expected_output.push_back(static_cast<uint8_t>(val & 0xFF));
        expected_output.push_back(static_cast<uint8_t>((val >> 8) & 0xFF));
    }

    return Test(src_mgr, source_code, expected_output, false);
}

Expression_test::Test Expression_test::create_expression_div_zero_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));
    add_line("bad_val = 100 / 0");
    add_line("    .word bad_val");

    return Test(src_mgr, source_code, {}, true);
}

Expression_test::Test Expression_test::create_expression_mod_zero_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));
    add_line("bad_val = 50 % 0");
    add_line("    .word bad_val");

    return Test(src_mgr, source_code, {}, true);
}

Expression_test::Test Expression_test::create_expression_mismatched_parens_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));
    add_line("bad_val = (10 + 20 * 5"); // Missing closing parenthesis
    add_line("    .word bad_val");

    return Test(src_mgr, source_code, {}, true);
}

Expression_test::Test Expression_test::create_expression_missing_operand_test()
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));
    add_line("bad_val = 100 + * 5"); // Missing operand between operators
    add_line("    .word bad_val");

    return Test(src_mgr, source_code, {}, true);
}

std::vector<Expression_test::Test> Expression_test::create_unit_tests()
{
    return {
        create_expression_operators_test(),
        create_expression_order_of_operations_test(),
        create_expression_div_zero_test(),
        create_expression_mod_zero_test(),
        create_expression_mismatched_parens_test(),
        create_expression_missing_operand_test()
    };
}

int Expression_test::test(int col, bool exit_on_fail)
{
    constexpr int fileid = 0;
    std::stringstream ss;

    bool overall_passed = true;
    int passed_count = 0;
    int failed_count = 0;

    auto tests = create_unit_tests();
    auto total_tests = tests.size();
    PasmTokenizer tokenizer;
    Options options;
    options.verbose = false;

    for (auto& test : tests) {
        bool test_passed = false;
        try {

            std::string source_code = test.source_code;
            auto tokens = tokenizer.tokenize(source_code, fileid);
            AssemblerParser parser(tokens, options, test.src_mgr);
            auto statements = parser.ParseProgram(tokenizer);
            MultiPassAssembler assembler(options);
            assembler.Assemble(statements, test.src_mgr);

            if (test.negative_test) {
                // Assembly succeeded when it should have thrown an exception
                test_passed = false;
                ss << "FAILED (Negative Test): Assembly succeeded on invalid input.\n";
            } else {
                test_passed = (test.expected == assembler.binary_output);
            }
        } 
        catch (std::exception& ex) {
            if (test.negative_test) {
                // Exception was expected
                test_passed = true;
            } else {
                test_passed = false;
                ss << std::format("FAILED with exception: {}\n", ex.what());
            }
        }

        if (test_passed) {
            ++passed_count;
            
            std::cout << std::format("{}{} {}PASSED: {:4} of {} ", es.column(col), es.ERASE_CURSOR_EOL, 
                es.gr(es.BRIGHT_GREEN_FOREGROUND), passed_count, total_tests);
            
        } else {
            ++failed_count;
            overall_passed = false;

            std::cout << std::format("{}{} {}PASSED: {:4} {}FAILED: {}", es.column(col), es.ERASE_CURSOR_EOL, 
                es.gr(es.BRIGHT_GREEN_FOREGROUND), passed_count, es.gr(es.BRIGHT_RED_FOREGROUND), failed_count);
                
                
            
            error = ss.str();
            if (exit_on_fail) {
                return overall_passed;
            }
        }
    }

    return overall_passed;
}
