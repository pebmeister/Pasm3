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

#define DEFINE_ANSI_ES
#include "ANSI_esc.h"
#undef DEFINE_ANSI_ES

#include "opcode_test.h"
#include "label_test.h"
#include "expression_test.h"
#include "macro_test.h"
#include "loop_test.h"

/**
 * @brief Holds configuration flags and parameters parsed from command-line arguments.
 */
struct Test_Options {
    bool test_opcode = false;             ///< Flag indicating whether to execute opcode verification tests.
    bool test_labels = false;             ///< Flag indicating whether to execute label verification tests.
    bool test_expression = false;         ///< Flag indicating whether to execute Expression verification tests.
    bool test_macros = false;              ///< Flag indicating whether to execute Macro verification tests.
    bool test_loops = false;              ///< Flag indicating whether to execute loop verification tests.
    int  opcode_max_iteration = 0xFF;     ///< Maximum operand loop iterations per addressing mode test.
    int  label_max_iteration = 0xFF;      ///< Maximum label iterations per test.
    int  expression_max_iteration = 1;    ///< Maximum expression iterations per test.
    int  macro_max_iteration = 20;        ///< Maximum macro iterations per test.
    int  loop_max_iteration = 25;         ///< Maximum loop iterations per test.
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
    options.test_opcode = false;
    options.test_labels = false;
    options.test_expression = false;
    options.test_macros = false;
    options.test_loops = false;
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
        else if (arg == "-label") {
            options.test_labels = true;
            if (arg_num < argc) {
                options.label_max_iteration = std::stoi(argv[arg_num++]);
                if (options.label_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.opcode_max_iteration));
                }
            }
        }
        else if (arg == "-expr") {
            options.test_expression = true;
            if (arg_num < argc) {
                options.expression_max_iteration = std::stoi(argv[arg_num++]);
                if (options.expression_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.opcode_max_iteration));
                }
            }
        }        
        else if (arg == "-macro") {
            options.test_macros = true;
            if (arg_num < argc) {
                options.macro_max_iteration = std::stoi(argv[arg_num++]);
                if (options.macro_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.opcode_max_iteration));
                }
            }
        }        
        else if (arg == "-loop") {
            options.test_loops = true;
            if (arg_num < argc) {
                options.loop_max_iteration = std::stoi(argv[arg_num++]);
                if (options.loop_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.opcode_max_iteration));
                }
            }
        }        
        else if (arg == "-all") {
            options.test_opcode = true;
            options.test_labels = true;
            options.test_expression = true;
            options.test_macros = true;
            options.test_loops = true;
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

    
    int result = 0;
    try {
        Test_Options options;    
        
        options.test_opcode = true;
        options.test_labels = true;
        options.test_expression = true;
        options.test_macros = true;
        options.test_loops = true;

        if (argc > 1) {
            parse_args(argc, argv, options);
        }
        
        if (options.test_opcode) {
            Opcode_test op_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "OPCODE TEST");
            result = op_test.test(15, true, options.opcode_max_iteration);        
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), op_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }
        if (options.test_labels) {
            Label_test lab_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "LABEL TEST");
            result = lab_test.test(15, true, options.label_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), lab_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }

        if (options.test_expression) {
            Expression_test ex_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "EXPR TEST");
            result = ex_test.test(15, true, options.expression_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), ex_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }
        if (options.test_macros) {
            Macro_test macro_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "MACRO TEST");
            result = macro_test.test(15, true, options.macro_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), macro_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }
        if (options.test_loops) {
            Loop_test loop_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "LOOP TEST");
            result = loop_test.test(15, true, options.loop_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), loop_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }
    }
    catch (std::exception& ex) {
        std::cout << std::format("\n{}{}{}{}{}", 
            es.down(1), es.gr(es.BRIGHT_RED_FOREGROUND), ex.what(), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
        result = -1;
    }
    std::cout << std::format("{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR);
    std::cout << "\n";
    return 0;
}
