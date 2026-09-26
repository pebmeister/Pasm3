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

#define DEFINE_ANSI_ES
#include "ANSI_esc.h"
#undef DEFINE_ANSI_ES


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
                if (options.opcode_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iteratiions {}. Must be greater than zero.", options.opcode_max_iteration));
                }
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
    std::cout << std::format("{}{}{}", es.HIDE_CURSOR, es.HOME, es.ERASE_ALL_DISPLAY);

    Test_Options options;    
    auto line = 1;
    try {
        parse_args(argc, argv, options);
        
        if (options.test_opcode) {
            std::cout << std::format("{}{}{}", es.pos(line,1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "OPCODE TEST");

            Opcode_test op_test;
            op_test.test(options.opcode_max_iteration, line, 15, true);
            line++;
        }
    }
    catch (std::exception& ex) {
        std::cout << std::format("{}{}", es.pos(line + 1,1), es.gr(es.BRIGHT_RED_FOREGROUND));
        std::cout << ex.what();
        std::cout << std::format("{}{}{}", es.pos(line + 5,1), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
        return -1;
    }
    std::cout << std::format("{}{}{}", es.pos(line,1), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
    
    return 0;
}