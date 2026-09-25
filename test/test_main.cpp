/**
 * @file test_main.cpp
 * @brief Main entry point for the PASM 6502 multi-pass assembler CLI tool.
 * @author Paul Baxter
 * @details Handles command-line option parsing, source loading, tokenization,
 *          parsing, multi-pass binary assembly, and binary/PRG output generation.
 */

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <filesystem>
#include <format>
#include <cctype>

#define GEN_RULEMAP
#include "ruletype.h"
#undef GEN_RULEMAP

#define GEN_TOKMAP
#include "tokenkind.h"
#undef GEN_TOKMAP

#include "opcode_test.h"

struct Test_Options {
    bool test_opcode = false;
    int  opcode_max_iteration = 0xFF;
};

void parse_args(int argc, char* argv[], Test_Options& options);


void parse_args(int argc, char* argv[], Test_Options& options)
{
    auto arg_num = 1;
    while (arg_num < argc) {
        std::string arg = std::string(argv[arg_num++]);
        
        if (arg == "-opcode") {
            options.test_opcode = true;
            if (arg_num < argc) {
                options.opcode_max_iteration = std::stoi(argv[arg_num++]);
            }
        }
        else if (arg == "-all") {
            options.test_opcode = true;
        }
        else {
            throw std::runtime_error(std::format("Unknown command line option {}", arg));
        }
    }
}

int main(int argc, char* argv[])
{    
    Test_Options options;
    
    try {
        parse_args(argc, argv, options);

        if (options.test_opcode) {
            
            Opcode_test op_test;
            op_test.test(options.opcode_max_iteration);
            std::cout <<
                std::format("OPCODE TEST:  {} PASSED  {} FAILED\n", op_test.passed, op_test.failed);
        }
    }
    catch (std::exception& ex) {
        std::cout <<
            ex.what();
        return -1;
    }
    return 0;
}