#pragma once 
#include <string>

#include "sourceManager.h"

class Label_test {
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
    
    Test create_global_labels_test();
    Test create_foward_labels_test();
    std::vector<Test> create_unit_tests();
    
public:
    std::string error;
    int test(int col); 
};