#pragma once
#include <vector>
#include <cctype>


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


class Macro_test  : public TestRunner {

private:
    Test create_macro_test(int max);

public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        emit(create_macro_test(max_iterations));
    }
};