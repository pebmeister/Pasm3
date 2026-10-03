#pragma once 
#include <string>

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


class Label_test : public TestRunner {
private:
    Test create_global_labels_test();
    Test create_foward_labels_test();
    int max = 0;
    
public:
    std::vector<Test> create_unit_tests(int max_iterations) override 
    {
        max = max_iterations = 0;
        return {
            create_global_labels_test(),
            create_foward_labels_test()
        };
    }
};