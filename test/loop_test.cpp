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
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    std::vector<uint8_t> expected_output;
    src_mgr.files.push_back("Loop_test");

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    add_line(std::format("    * = {}", org));
    add_line(std::format(".var VAL = 0"));
    add_line(std::format(".while VAL < {}", max_iterations));
    add_line(std::format("    .word VAL"));
    add_line(std::format("    VAL = VAL + 1"));
    add_line(std::format(".wend"));

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
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;

    std::vector<uint8_t> expected_output;
    src_mgr.files.push_back("Loop_test");

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    add_line(std::format("    * = {}", org));
    add_line(std::format(".var VAL = 0"));
    add_line(std::format(".while VAL < {}", max_iterations));
    add_line(std::format("    .word VAL"));
    add_line(std::format("    VAL = VAL + 1"));
    add_line(std::format(".wend"));

    auto val = 0;
    while (val < max_iterations) 
    {
        expected_output.push_back(val & 0xFF);
        expected_output.push_back((val >> 8) & 0xFF);        
        val++;
    }
    
    return Test(src_mgr, source_code, expected_output, false);    
}


Loop_test::Test Loop_test::create_while_nested_test(int max_iterations)
{    
    constexpr int fileid = 0;
    constexpr int org = 0x0100;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    src_mgr.files.push_back("Loop_test");

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };
    
    add_line(std::format("    * = {}", org));

    // 1. Declare all variables initially
    for (auto n = 0; n < max_iterations; ++n) {
        add_line(std::format(".var val{} = 0", n));
    }
    add_line();

    // 2. Generate the nested .while blocks
    for (auto n = 0; n < max_iterations; ++n) {
        std::string indent((n + 1) * 4, ' ');
        // Reset the counter before starting the inner loop
        add_line(std::format("{}val{} = 0", indent, n));
        add_line(std::format("{}.while val{} < {}", indent, n, max_iterations));
        
        // Emulate the word payload inside the loop
        std::string body_indent((n + 2) * 4, ' ');
        add_line(std::format("{}.word val{}", body_indent, n));
    }   
    
    // 3. Generate the increments and .wend closures inside-out
    for (auto n = max_iterations - 1; n >= 0; --n) {
        std::string indent((n + 1) * 4, ' ');
        std::string body_indent((n + 2) * 4, ' ');
        
        // Increment the counter at the bottom of the loop body
        add_line(std::format("{}val{} = val{} + 1", body_indent, n, n));
        add_line(std::format("{}.wend", indent));
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


