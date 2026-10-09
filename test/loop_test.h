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
    
public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        // Stream tests individually directly into the queue
        emit(create_basic_while_loop_test(max_iterations));
        emit(create_basic_repeat_loop_test(max_iterations));
        emit(create_while_loop_nested_test(std::min(max_iterations, 5 )));
        emit(create_repeat_loop_nested_test(std::min(max_iterations, 5 )));
        emit(create_mixed_loop_nested_test(std::min(max_iterations, 5 )));
    }
};
