#include <sstream>
#include <format>
#include <string>

#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"
#include "ANSI_esc.h"

#include "loop_test.h"


Loop_test::Test Loop_test::create_basic_while_loop_test(int max_iterations)
{
    const std::string name = "create_basic_while_loop_test";
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    std::vector<uint8_t> expected_output;
    src_mgr.files.push_back(name);

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line();
    add_line(std::format("{}; {}", Tab(0), name));
    add_line();
    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.var VAL = 0", Tab(0)));
    add_line(std::format("{}.while VAL < {}", Tab(0), max_iterations));
    add_line(std::format("{}.word VAL", Tab(1)));
    add_line(std::format("{}VAL = VAL + 1", Tab(1)));
    add_line(std::format("{}.wend", Tab(0)));

    auto val = 0;
    while (val < max_iterations) 
    {
        expected_output.push_back(val & 0xFF);
        expected_output.push_back((val >> 8) & 0xFF);        
        val++;
    }
    
    return Test(src_mgr, source_code, expected_output, false);    
}

Loop_test::Test Loop_test::create_basic_repeat_loop_test(int max_iterations)
{
    const std::string name = "create_basic_repeat_loop_test";
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    std::vector<uint8_t> expected_output;
    src_mgr.files.push_back(name);

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line();
    add_line(std::format("{}; {}", Tab(0), name));
    add_line();
    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    add_line(std::format("{}.var VAL = 0", Tab(0)));
    add_line(std::format("{}.repeat", Tab(0)));
    add_line(std::format("{}.word VAL", Tab(1)));
    add_line(std::format("{}VAL = VAL + 1", Tab(1)));
    add_line(std::format("{}.until VAL >= {}", Tab(0), max_iterations));

    auto val = 0;
    do
    {
        expected_output.push_back(val & 0xFF);
        expected_output.push_back((val >> 8) & 0xFF);        
        val++;
    }  while (val < max_iterations);

    return Test(src_mgr, source_code, expected_output, false);
}

Loop_test::Test Loop_test::create_while_loop_nested_test(int max_iterations)
{    
    const std::string name = "create_while_loop_nested_test";
    constexpr int fileid = 0;
    constexpr int org = 0x0100;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    src_mgr.files.push_back(name);

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line();
    add_line(std::format("{}; {}", Tab(0), name));
    add_line();
    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();

    // 1. Declare all variables initially
    for (auto n = 0; n < max_iterations; ++n) {
        add_line(std::format("{}.var val{} = 0", Tab(0), n));
    }
    add_line();

    // 2. Generate the nested .while blocks
    for (auto n = 0; n < max_iterations; ++n) {
        // Reset the counter before starting the inner loop
        add_line(std::format("{}val{} = 0", Tab(n), n));
        add_line(std::format("{}.while val{} < {}", Tab(n), n, max_iterations));
        
        // Emulate the word payload inside the loop
        add_line(std::format("{}.word val{}", Tab(n + 1), n));
    }   
    
    // 3. Generate the increments and .wend closures inside-out
    for (auto n = max_iterations - 1; n >= 0; --n) {
        // Increment the counter at the bottom of the loop body
        add_line(std::format("{}val{} = val{} + 1", Tab(n + 1), n, n));
        add_line(std::format("{}.wend", Tab(n)));
    }
    
    std::vector<int> vars(max_iterations, 0);
    
    // 4. Recursive function to exactly simulate the nested loops
    std::function<void(int)> simulate_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        vars[depth] = 0; // Reset counter for this depth

        while (vars[depth] < max_iterations) {
            // Emulate .word valN
            expected_output.push_back(vars[depth] & 0xFF);
            expected_output.push_back((vars[depth] >> 8) & 0xFF);        

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }

            // Execute deeper nested loops
            simulate_loop(depth + 1);

            // Increment counter at the end of the loop
            vars[depth]++;
        }
    };

    // Start simulation at the outermost loop
    simulate_loop(0);
    return Test(src_mgr, source_code, expected_output, false);    
}

Loop_test::Test Loop_test::create_repeat_loop_nested_test(int max_iterations)
{    
    const std::string name = "create_repeat_loop_nested_test";
    constexpr int fileid = 0;
    constexpr int org = 0x0100;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    src_mgr.files.push_back(name);

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line();
    add_line(std::format("{}; {}", Tab(0), name));
    add_line();
    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();

    // 1. Declare all variables initially
    for (auto n = 0; n < max_iterations; ++n) {
        add_line(std::format("{}.var val{} = 0", Tab(0), n));
    }
    add_line();

    // 2. Generate the nested .while blocks
    for (auto n = 0; n < max_iterations; ++n) {
        // Reset the counter before starting the inner loop
        add_line(std::format("{}val{} = 0", Tab(n), n));
        add_line(std::format("{}.repeat", Tab(n)));
        
        // Emulate the word payload inside the loop
        add_line(std::format("{}.word val{}", Tab(n + 1), n));
    }   
    
    // 3. Generate the increments and .wend closures inside-out
    for (auto n = max_iterations - 1; n >= 0; --n) {
        // Increment the counter at the bottom of the loop body
        add_line(std::format("{}val{} = val{} + 1", Tab(n + 1), n, n));
        add_line(std::format("{}.until val{} >= {}", Tab(n), n, max_iterations));
    }
    
    std::vector<int> vars(max_iterations, 0);
    
    // 4. Recursive function to exactly simulate the nested loops
    std::function<void(int)> simulate_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        vars[depth] = 0; // Reset counter for this depth

        while (vars[depth] < max_iterations) {
            // Emulate .word valN
            expected_output.push_back(vars[depth] & 0xFF);
            expected_output.push_back((vars[depth] >> 8) & 0xFF);        

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }

            // Execute deeper nested loops
            simulate_loop(depth + 1);

            // Increment counter at the end of the loop
            vars[depth]++;
        }
    };

    // Start simulation at the outermost loop
    simulate_loop(0);
    
    return Test(src_mgr, source_code, expected_output, false);    
}

Loop_test::Test Loop_test::create_mixed_loop_nested_test(int max_iterations)
{    
    const std::string name = "create_mixed_loop_nested_test";
    constexpr int fileid = 0;
    constexpr int org = 0x0100;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    src_mgr.files.push_back(name);

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line();
    add_line(std::format("{}; {}", Tab(0), name));
    add_line();
    add_line(std::format("{}* = {}", Tab(0), org));
    add_line();
    
    add_line(std::format("{}.var VAL1 = 0", Tab(0)));
    add_line(std::format("{}.while VAL1 < {}", Tab(0), max_iterations));
    add_line(std::format("{}.word VAL1", Tab(1)));    
    add_line(std::format("{}.var VAL2 = 0", Tab(1)));
    add_line(std::format("{}.repeat", Tab(1)));
    add_line(std::format("{}.word VAL2", Tab(2)));
    add_line(std::format("{}.var VAL3 = 0", Tab(2)));
    add_line(std::format("{}.while VAL3 < {}", Tab(2), max_iterations));
    add_line(std::format("{}.word VAL3", Tab(3))); 
    add_line(std::format("{}.var VAL4 = 0", Tab(3)));
    add_line(std::format("{}.repeat", Tab(3)));
    add_line(std::format("{}.word VAL4", Tab(4)));    
    add_line(std::format("{}VAL4 = VAL4 + 1", Tab(4)));
    add_line(std::format("{}.until VAL4 >= {}", Tab(3), max_iterations));
    add_line(std::format("{}VAL3 = VAL3 + 1", Tab(3)));    
    add_line(std::format("{}.wend", Tab(2)));
    add_line(std::format("{}VAL2 = VAL2 + 1", Tab(2)));
    add_line(std::format("{}.until VAL2 >= {}", Tab(1), max_iterations));
    add_line(std::format("{}VAL1 = VAL1 + 1", Tab(1)));    
    add_line(std::format("{}.wend", Tab(0)));

    constexpr int max_depth = 4;
    std::vector<int> vars(max_depth, 0);
    std::function<void(int)> simulate_loop = [&](int depth) {
        if (depth >= max_depth) return;

        vars[depth] = 0; // Reset counter for this depth

        while (vars[depth] < max_iterations) {
            // Emulate .word valN
            expected_output.push_back(vars[depth] & 0xFF);
            expected_output.push_back((vars[depth] >> 8) & 0xFF);        

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }

            // Execute deeper nested loops
            simulate_loop(depth + 1);

            // Increment counter at the end of the loop
            vars[depth]++;
        }
    };
    
    // Start simulation at the outermost loop
    simulate_loop(0);

    return Test(src_mgr, source_code, expected_output, false);        
}