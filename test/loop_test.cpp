#include <sstream>
#include <format>
#include <string>
#include <vector>
#include <functional>
#include <stdexcept>

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

    int val = 0;
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

    int val = 0;
    do
    {
        expected_output.push_back(val & 0xFF);
        expected_output.push_back((val >> 8) & 0xFF);        
        val++;
    } while (val < max_iterations);

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
    for (int n = 0; n < max_iterations; ++n) {
        add_line(std::format("{}.var val{} = 0", Tab(0), n));
    }
    add_line();

    // 2. Build nested loop assembly structure recursively
    std::function<void(int)> build_asm_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        add_line(std::format("{}val{} = 0", Tab(depth), depth));
        add_line(std::format("{}.while val{} < {}", Tab(depth), depth, max_iterations));
        add_line(std::format("{}.word val{}", Tab(depth + 1), depth));

        build_asm_loop(depth + 1);

        add_line(std::format("{}val{} = val{} + 1", Tab(depth + 1), depth, depth));
        add_line(std::format("{}.wend", Tab(depth)));
    };

    build_asm_loop(0);

    // 3. Exact simulation matching assembly execution pattern
    std::vector<int> vars(max_iterations, 0);
    std::function<void(int)> simulate_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        vars[depth] = 0;
        while (vars[depth] < max_iterations) {
            expected_output.push_back(vars[depth] & 0xFF);
            expected_output.push_back((vars[depth] >> 8) & 0xFF);

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }

            simulate_loop(depth + 1);
            vars[depth]++;
        }
    };

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
    for (int n = 0; n < max_iterations; ++n) {
        add_line(std::format("{}.var val{} = 0", Tab(0), n));
    }
    add_line();

    // 2. Build nested repeat assembly structure recursively
    std::function<void(int)> build_asm_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        add_line(std::format("{}val{} = 0", Tab(depth), depth));
        add_line(std::format("{}.repeat", Tab(depth)));
        add_line(std::format("{}.word val{}", Tab(depth + 1), depth));

        build_asm_loop(depth + 1);

        add_line(std::format("{}val{} = val{} + 1", Tab(depth + 1), depth, depth));
        add_line(std::format("{}.until val{} >= {}", Tab(depth), depth, max_iterations));
    };

    build_asm_loop(0);

    // 3. Exact post-test do-while simulation
    std::vector<int> vars(max_iterations, 0);
    std::function<void(int)> simulate_loop = [&](int depth) {
        if (depth >= max_iterations) return;

        vars[depth] = 0;
        do {
            expected_output.push_back(vars[depth] & 0xFF);
            expected_output.push_back((vars[depth] >> 8) & 0xFF);

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }

            simulate_loop(depth + 1);
            vars[depth]++;
        } while (vars[depth] < max_iterations);
    };

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
    
    // Declare variables globally at standard start scope
    add_line(std::format("{}.var VAL1 = 0", Tab(0)));
    add_line(std::format("{}.var VAL2 = 0", Tab(0)));
    add_line(std::format("{}.var VAL3 = 0", Tab(0)));
    add_line(std::format("{}.var VAL4 = 0", Tab(0)));
    add_line();

    // Assembly generation
    add_line(std::format("{}VAL1 = 0", Tab(0)));
    add_line(std::format("{}.while VAL1 < {}", Tab(0), max_iterations));
    add_line(std::format("{}.word VAL1", Tab(1)));    
    add_line(std::format("{}VAL2 = 0", Tab(1)));
    add_line(std::format("{}.repeat", Tab(1)));
    add_line(std::format("{}.word VAL2", Tab(2)));
    add_line(std::format("{}VAL3 = 0", Tab(2)));
    add_line(std::format("{}.while VAL3 < {}", Tab(2), max_iterations));
    add_line(std::format("{}.word VAL3", Tab(3))); 
    add_line(std::format("{}VAL4 = 0", Tab(3)));
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

    auto push_word = [&](int val) {
        expected_output.push_back(val & 0xFF);
        expected_output.push_back((val >> 8) & 0xFF);
    };

    // Correct structural simulation matching exact assembly payload order
    int val1 = 0;
    while (val1 < max_iterations) {
        push_word(val1);

        int val2 = 0;
        do {
            push_word(val2);

            int val3 = 0;
            while (val3 < max_iterations) {
                push_word(val3);

                int val4 = 0;
                do {
                    push_word(val4);
                    val4++;
                } while (val4 < max_iterations);

                val3++;
            }

            val2++;
        } while (val2 < max_iterations);

        val1++;
    }

    return Test(src_mgr, source_code, expected_output, false);        
}
