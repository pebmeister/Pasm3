#pragma once
#include <vector>
#include <cctype>


#include "optype.h"
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


class Macro_lib_test  : public TestRunner {

private:
    Test create_macro_PUSH16_test(int max_iterations);
    Test create_macro_POP16_test(int max_iterations);
    Test create_macro_STORE8_test(int max_iterations);

public:

    void prepair_tests() override {}
    void cleanup_tests() override {}

    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        emit(create_macro_PUSH16_test(max_iterations));
        emit(create_macro_POP16_test(max_iterations));
        emit(create_macro_STORE8_test(max_iterations));
    }
};
