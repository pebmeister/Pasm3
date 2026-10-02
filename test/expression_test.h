#pragma once

#include <string>
#include <string_view>
#include <vector>
#include <cstdint>
#include "sourceManager.h"

class Expression_test {
public:
    struct Test {
        SourceManager src_mgr;
        std::string source_code;
        std::vector<uint8_t> expected;
        bool negative_test;

        Test(
            SourceManager src_mgr,
            std::string_view source_code,
            std::vector<uint8_t> expected,
            bool negative_test = false) 
            : src_mgr(std::move(src_mgr)),
              source_code(std::move(source_code)),
              expected(std::move(expected)),
              negative_test(negative_test) {}
    };

    Test create_expression_order_of_operations_test();
    Test create_expression_operators_test();

    // Negative Tests
    Test create_expression_div_zero_test();
    Test create_expression_mod_zero_test();
    Test create_expression_mismatched_parens_test();
    Test create_expression_missing_operand_test();
    
    std::vector<Test> create_unit_tests();

public:
    std::string error;
    int test(int col, bool exit_on_fail);
};