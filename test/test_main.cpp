/**
 * @file test_main.cpp
 * @author Paul Baxter
 * @brief Main entry point for the PASM 6502 assembler test suite executable.
 * @version 1.0
 * @date 2026-09-28
 * @details Handles command-line option parsing for test configurations, initializes 
 *          terminal UI states via ANSI escape codes, and runs automated opcode testing routines.
 */

#include <cassert>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <filesystem>
#include <format>
#include <cctype>


#define GEN_OPMAP
#include "optype.h"
#undef GEN_OPMAP

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
#include "control_flow_test.h"
#include "directives_test.h"

#include "parseargs.h"

// Helper class to construct C-style argc/argv arrays from standard strings
class ArgBuilder {
public:
    std::vector<std::string> storage;
    std::vector<char*> argv;

    ArgBuilder(std::initializer_list<std::string> args) {
        storage.reserve(args.size());
        for (const auto& arg : args) {
            storage.push_back(arg);
        }
        argv.reserve(storage.size() + 1);
        for (auto& s : storage) {
            argv.push_back(s.data());
        }
        argv.push_back(nullptr);
    }

    int argc() const { return static_cast<int>(storage.size()); }
    char** data() { return argv.data(); }
};

// RAII Guard to suppress std::cout (and optionally std::cerr) during a code block
class SuppressOutput {
private:
    std::ostringstream dummy;         // Declared FIRST so it constructs before rdbuf() is called
    std::streambuf* old_cout_buf;     // Declared SECOND

public:
    SuppressOutput() 
        : dummy(), 
          old_cout_buf(std::cout.rdbuf(dummy.rdbuf())) {}

    ~SuppressOutput() { 
        std::cout.rdbuf(old_cout_buf); 
    }
};

void test_options() {
    
    SuppressOutput suppress;
    
    // 1. Default Option Verification
    {
        ArgBuilder args{"pasm3", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.input_filenames.size() == 1);
        assert(opt.input_filenames[0] == "input.asm");
        assert(opt.cpu == CPU::_6502);
        assert(!opt.verbose);
        assert(!opt.c64);
        assert(!opt.debug);
        assert(!opt.launch);
        assert(!opt.cart);
        assert(!opt.d64);
        assert(!opt.autoloader);
        assert(!opt.vs);
        assert(!opt.xref);
        assert(opt.max_pass == 10);
    }

    // 2. Output File (-o)
    {
        ArgBuilder args{"pasm3", "-o", "output.bin", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.out);
        assert(opt.outfile == "output.bin");
    }

    // 3. Verbose Flag (-v)
    {
        ArgBuilder args{"pasm3", "-v", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.verbose);
    }

    // 4. Commodore 64 Format (-c64)
    {
        ArgBuilder args{"pasm3", "-c64", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.c64);
        assert(opt.input_filenames.size() == 1);
        assert(opt.input_filenames[0] == "input.asm");
    }

    // 5. Target CPU (-cpu)
    {
        // Test 65C02 explicit setting
        ArgBuilder args1{"pasm3", "-cpu", "65c02", "input.asm"};
        Options opt1 = parse_args(args1.argc(), args1.data());
        assert(opt1.cpu == CPU::_65C02);

        // Test 6502 explicit setting
        ArgBuilder args2{"pasm3", "-cpu", "6502", "input.asm"};
        Options opt2 = parse_args(args2.argc(), args2.data());
        assert(opt2.cpu == CPU::_6502);

        // Test invalid CPU error
        bool caught = false;
        try {
            ArgBuilder args3{"pasm3", "-cpu", "z80", "input.asm"};
            parse_args(args3.argc(), args3.data());
        } catch (const std::runtime_error&) {
            caught = true;
        }
        assert(caught);
    }

    // 6. Include Directories (-i)
    {
        ArgBuilder args{"pasm3", "-i", "include/dir1", "-i", "include/dir2", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.include.size() == 2);
        assert(opt.include[0] == "include/dir1");
        assert(opt.include[1] == "include/dir2");
    }

    // 7. Symbol Tracing (-st)
    {
        ArgBuilder args{"pasm3", "-st", "MY_LABEL", "-st", "TEMP_VAR", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.traced_symbols.size() == 2);
        assert(opt.traced_symbols[0] == "MY_LABEL");
        assert(opt.traced_symbols[1] == "TEMP_VAR");
    }

    // 8. Command-Line Defined Symbols (-d)
    {
        // Decimal and Hexadecimal value definitions
        ArgBuilder args{"pasm3", "-d", "MAX_LEN", "255", "-d", "BASE_ADDR", "$C000", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.defined_symbols.size() == 2);
        assert(opt.defined_symbols[0].first == "MAX_LEN");
        assert(opt.defined_symbols[0].second == 255);
        assert(opt.defined_symbols[1].first == "BASE_ADDR");
        assert(opt.defined_symbols[1].second == 0xC000);
    }

    // 9. Cartridge Conversion Options (-cart)
    {
        ArgBuilder args{"pasm3", "-cart", "\"-t ultimax\"", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.cart);
        assert(opt.cart_options == "\"-t ultimax\"");
    }

    // 10. D64 Disk Image Creation (-d64)
    {
        ArgBuilder args{"pasm3", "-d64", "mydisk.d64", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.d64);
        assert(opt.d64_diskname == "mydisk.d64");
    }

    // 11. Autoloader Flag (-al)
    {
        ArgBuilder args{"pasm3", "-al", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.autoloader);
        assert(opt.d64); // -al automatically sets -d64
    }

    // 12. VICE Integration Options (-debug, -run, -vs)
    {
        ArgBuilder args{"pasm3", "-debug", "-vs", "symbols.vs", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.debug);
        assert(opt.vs);
        assert(opt.vs_name == "symbols.vs");
    }

    // 13. Max Pass Count (-mp)
    {
        ArgBuilder args{"pasm3", "-mp", "20", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.max_pass == 20);
    }

    // 14. Cross Reference Symbol File (-xref)
    {
        ArgBuilder args{"pasm3", "-xref", "input.asm"};
        Options opt = parse_args(args.argc(), args.data());
        assert(opt.xref);
    }

    // 15. Conflicting Arguments Check (-run and -debug)
    {
        bool caught = false;
        try {
            ArgBuilder args{"pasm3", "-run", "-debug", "input.asm"};
            parse_args(args.argc(), args.data());
        } catch (const std::runtime_error&) {
            caught = true;
        }
        assert(caught);
    }

    // 16. Missing Input File Check
    {
        bool caught = false;
        try {
            ArgBuilder args{"pasm3", "-v"};
            parse_args(args.argc(), args.data());
        } catch (const std::runtime_error&) {
            caught = true;
        }
        assert(caught);
    }
}

/**
 * @brief Holds configuration flags and parameters parsed from command-line arguments.
 */
struct Test_Options {
    bool test_opcode = false;             ///< Flag indicating whether to execute opcode verification tests.
    bool test_labels = false;             ///< Flag indicating whether to execute label verification tests.
    bool test_expression = false;         ///< Flag indicating whether to execute Expression verification tests.
    bool test_macros = false;             ///< Flag indicating whether to execute Macro verification tests.
    bool test_loops = false;              ///< Flag indicating whether to execute loop verification tests.
    bool test_control = false;            ///< Flag indicating whether to execute control verification tests.
    bool test_directives = false;         ///< Flag indicating whether to execute directive verification tests.
    bool test_parseargs = false;          ///< Flag indicating whether to execute directive verification tests.

    int  opcode_max_iteration = 0xFF;     ///< Maximum operand loop iterations per addressing mode test.
    int  label_max_iteration = 0xFF;      ///< Maximum label iterations per test.
    int  expression_max_iteration = 1;    ///< Maximum expression iterations per test.
    int  macro_max_iteration = 20;        ///< Maximum macro iterations per test.
    int  loop_max_iteration = 25;         ///< Maximum loop iterations per test.
    int  control_max_iteration = 25;      ///< Maximum control iterations per test.
    int  directive_max_iteration = 25;    ///< Maximum directive iterations per test.
};

/**
 * @brief Parses command-line arguments and updates the test options configuration.
 * 
 * @param argc Number of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @param options Reference to a Test_Options structure to populate.
 * @throws std::runtime_error Throws an error if an unknown option is encountered or if iteration counts are invalid.
 */
void parse_test_args(int argc, char* argv[], Test_Options& options);

/**
 * @brief Parses command-line arguments implementation.
 */
void parse_test_args(int argc, char* argv[], Test_Options& options)
{
    options.test_opcode = false;
    options.test_labels = false;
    options.test_expression = false;
    options.test_macros = false;
    options.test_loops = false;
    options.test_control = false;
    options.test_directives = false;
    options.test_parseargs = false;
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
        
        else if (arg == "-args") {
            options.test_parseargs = true;
        }
        
        else if (arg == "-control") {
            options.test_control = true;
            if (arg_num < argc) {
                options.control_max_iteration = std::stoi(argv[arg_num++]);
                if (options.control_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.control_max_iteration));
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
        else if (arg == "-directive") {
            options.test_directives = true;
            if (arg_num < argc) {
                options.directive_max_iteration = std::stoi(argv[arg_num++]);
                if (options.directive_max_iteration < 1) {
                    throw std::runtime_error(std::format("invalid value for max iterations {}. Must be greater than zero.", options.directive_max_iteration));
                }
            }
        }        
        else if (arg == "-all") {
            options.test_opcode = true;
            options.test_labels = true;
            options.test_expression = true;
            options.test_macros = true;
            options.test_loops = true;
            options.test_control = true;
            options.test_directives = true;
            options.test_parseargs = true;
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
        options.test_control = true;
        options.test_directives = true;
        options.test_parseargs = true;
        
        if (argc > 1) {
            parse_test_args(argc, argv, options);
        }
        
        if (options.test_parseargs) {
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "PARSE_ARGS");
            test_options();
                std::cout << std::format("{} {}PASSED: {:6}{}", 
                    es.column(15), 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), 
                    1, 
                    es.ERASE_CURSOR_EOL) << std::flush;
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
        if (options.test_control) {
            Control_flow_test control_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "CONTROL TEST");
            result = control_test.test(15, true, options.control_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), control_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
                return -1;
            }
        }

        if (options.test_directives) {
            Directives_test directive_test;
            std::cout << std::format("{}{}{}{:15}", es.down(1), es.column(1), es.gr(es.BRIGHT_YELLOW_FOREGROUND), "DIRECTIVE TEST");
            result = directive_test.test(15, true, options.directive_max_iteration);
            if (result) {
                std::cout << std::format("{}{}{}{}{}{}", es.down(1), es.column(1), es.gr(es.BRIGHT_RED_FOREGROUND), directive_test.source_code, es.gr(es.BRIGHT_WHITE_FOREGROUND), es.SHOW_CURSOR );
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
