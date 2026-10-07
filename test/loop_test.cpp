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


Loop_test::Test Loop_test::create_basic_loop_test(int max_iterations)
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



