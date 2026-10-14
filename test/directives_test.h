#pragma once 
#include <string>
#include <functional>

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

class Directives_test : public TestRunner {
private:
    Test create_incbin_full_file_test();
    Test create_incbin_offset_and_length_test();
    Test create_incbin_missing_file_negative_test();
    
    void create_temp_bin_file(const std::string& filename, const std::vector<uint8_t>& bytes);
    void remove_temp_file(const std::string& filename);

    int max = 0;
    
    std::string temp_files[2]  {
      "test_incbin_full.bin",
      "test_incbin_slice.bin",
    };

    std::vector<uint8_t> full_bytes = { 0xAA, 0xBB, 0x11, 0x22, 0x33, 0x44, 0xCC, 0xDD };
    std::vector<uint8_t> dummy_bytes = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 };

public:

    void prepair_tests() override {}    
    void cleanup_tests() override {}

    Directives_test() {
        const std::string temp_file1 = temp_files[0];
        create_temp_bin_file(temp_file1, full_bytes);
     
        const std::string temp_file2 =temp_files[1];
        create_temp_bin_file(temp_file2, dummy_bytes); 
    }

    ~Directives_test() {
        try {
            for (const auto& temp_file: temp_files) {
                remove_temp_file(temp_file);
            }
        }
        catch (...) {
        }
    }

    void generate_tests(int max_iterations, const std::function<void(Test)>& emit) override
    {
        max = max_iterations;

        // Stream tests individually directly into the queue
        emit(create_incbin_full_file_test());
        emit(create_incbin_offset_and_length_test());
        emit(create_incbin_missing_file_negative_test());
    }
};