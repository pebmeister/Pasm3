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

class Label_test : public TestRunner {
private:
    Test create_global_labels_test();
    Test create_foward_labels_test();
    Test create_anon_labels_test();
    Test create_local_label_test();
    Test create_combined_label_test();
    
    int max = 0;
    
public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        max = max_iterations;

        // Stream tests individually directly into the queue
        emit(create_global_labels_test());
        emit(create_foward_labels_test());
        emit(create_anon_labels_test());
        emit(create_local_label_test());
        emit(create_combined_label_test());
    }
};