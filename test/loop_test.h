#pragma once 
#include <string>
#include <functional>

#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"
#include "ANSI_esc.h"
#include "test_runner.h"

class Loop_test : public TestRunner {
private:

    inline std::string Tab(int level) { return std::string(level*4, ' '); }

    Test create_basic_while_loop_test(int max_iterations);
    Test create_basic_repeat_loop_test(int max_iterations);
    Test create_while_loop_nested_test(int max_iterations);
    Test create_repeat_loop_nested_test(int max_iterations);
    Test create_mixed_loop_nested_test(int max_iterations);
    Test create_while_continue_loop_test(int max_iterations, int continue_index);
    Test create_while_break_loop_test(int max_iterations, int break_index);
    Test create_while_loop_nested_continue_test(int max_iterations, int continue_j);
    
public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        // Stream tests individually directly into the queue
        for (auto i = 1; i <= max_iterations; ++i) {
            emit(create_basic_while_loop_test(i));
            emit(create_basic_repeat_loop_test(i));
            emit(create_while_loop_nested_test(std::min(i, 5 )));
            emit(create_repeat_loop_nested_test(std::min(i, 5 )));
            emit(create_mixed_loop_nested_test(std::min(i, 5 )));

            for (auto c = 1; c < max_iterations; ++c) {
                emit(create_while_continue_loop_test(i, c));
            }
            for (auto b = 1; b < max_iterations; ++b) {
                emit(create_while_break_loop_test(i, b));
            }
            for (auto j = 1; j < max_iterations; ++j) {
                emit(create_while_loop_nested_continue_test(i, j));
            }
        }
    }
};
