/**
 * @file test_main.cpp
 * @author Paul Baxter
 * @brief Main entry point for the PASM 6502 assembler test suite executable.
 * @version 1.0
 * @date 2026-09-28
 * @details Handles command-line option parsing for test configurations, initializes 
 *          terminal UI states via ANSI escape codes, and runs automated opcode testing routines.
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

/**
 * @brief Holds configuration flags and parameters parsed from command-line arguments.
 */
struct Test_Options {
    bool test_opcode = false;             ///< Flag indicating whether to execute opcode verification tests.
    int  opcode_max_iteration = 0xFF;     ///< Maximum operand loop iterations per addressing mode test.
};

/**
 * @brief Parses command-line arguments and updates the test options configuration.
 * 
 * @param argc Number of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @param options Reference to a Test_Options structure to populate.
 * @throws std::runtime_error Throws an error if an unknown option is encountered or if iteration counts are invalid.
 */
void parse_args(int argc, char* argv[], Test_Options& options);

/**
 * @brief Parses command-line arguments implementation.
 */
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
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.opcode_max_iteration));
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

/**
 * @brief Main execution entry point for the test harness.
 * 
 * Initializes the terminal view, parses input arguments, executes selected test suites 
 * (such as opcode validation), and outputs results or error diagnostics using ANSI formatting.
 * 
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return int Returns 0 upon successful execution completion.
 */
int main(int argc, char* argv[])
{    
    std::cout << std::format("{}", es.HIDE_CURSOR);

    Test_Options options;    
    Opcode_test op_test;
    auto line = 1;
    int result = 0;
    try {
        if (argc > 1) {
            parse_args(argc, argv, options);
        }
        else {
            options.test_opcode = true;
        }
        
        if (options.test_opcode) {
            std::cout << std::format("{}{}", es.gr(es.BRIGHT_YELLOW_FOREGROUND), "OPCODE TEST");
            result = op_test.test(options.opcode_max_iteration, line, 15, true);
            line++;
        }
    }
    catch (std::exception& ex) {
        std::cout << std::format("\n{}{}{}{}", 
            es.gr(es.BRIGHT_RED_FOREGROUND), ex.what(), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
        result = -1;
    }
    if (result) {
        std::cout << std::format("\n{}{}{}{}{}", es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), op_test.source, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
        return -1;
    }
    std::cout << std::format("\n{}{}{}", es.column(1), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
    return 0;
}
