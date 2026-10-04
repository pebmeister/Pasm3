#pragma once

#include <string>
#include <string_view>
#include <vector>
#include <cstdint>

#include "sourceManager.h"
#include "test_runner.h"

class Expression_test : public TestRunner
{   
private:
    Test create_expression_order_of_operations_test();
    Test create_expression_operators_test();

    // Negative Tests
    Test create_expression_div_zero_test();
    Test create_expression_mod_zero_test();
    Test create_expression_mismatched_parens_test();
    Test create_expression_missing_operand_test();
    
    int max = 0;

public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        max = max_iterations;
        emit(create_expression_operators_test());
        emit(create_expression_order_of_operations_test());
        emit(create_expression_div_zero_test());
        emit(create_expression_mod_zero_test());
        emit(create_expression_mismatched_parens_test());
        emit(create_expression_missing_operand_test());
    }

};