#pragma once
#include <string>
#include <vector>
#include <cstdint>
#include "sourceManager.h"
#include "test_runner.h"

class Control_flow_test: public TestRunner {
private:
    Test create_basic_if_test();
    Test create_if_else_test();
    Test create_nested_if_test();
    Test create_orphaned_else_test();
    Test create_orphaned_endif_test();
    Test create_unmatched_if_test();

    int max = 0;
    
public:
    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        max = max_iterations;

        // Stream tests individually directly into the queue
        emit(create_basic_if_test());
        emit(create_if_else_test());
        emit(create_nested_if_test());
        emit(create_orphaned_else_test());
        emit(create_orphaned_endif_test());
        emit(create_unmatched_if_test());
    }
};