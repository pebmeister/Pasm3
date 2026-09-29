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

#include "opcode_test.h"
#include "ANSI_esc.h"

#include "label_test.h"

int Label_test::test(int col)
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string line;
    std::string source_code;
    
    // build the oprg line
    std::string orgline = std::format("    * = {}", org);
    line = std::format("{}", orgline);
    src_mgr.source[{fileid, line_num}] = line;
    source_code += (line + "\n");
    line_num++;

    constexpr size_t num_global_labels = 10000;
    constexpr size_t bytes_per_labels = 2;

    std::vector<uint8_t> expected_output;
    
    uint16_t addr = static_cast<uint16_t>(org + num_global_labels * bytes_per_labels);
    uint16_t pc = org;
    for (size_t n = 0;  n < num_global_labels; ++n) {
        line = std::format("    .word Label{:04X}", n);
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
        
        uint8_t lo = static_cast<uint8_t>(addr & 0xFF);
        uint8_t hi = static_cast<uint8_t>((addr >> 8) & 0xFF);
        expected_output.push_back(lo);
        expected_output.push_back(hi);
        pc += 2;        
    }
    
    for (size_t n = 0;  n < num_global_labels; ++n) {
        line = std::format("Label{:04X}    .word ${:04X}", n, pc);
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
        uint8_t lo = static_cast<uint8_t>(pc & 0xFF);
        uint8_t hi = static_cast<uint8_t>((pc >> 8) & 0xFF);
        expected_output.push_back(lo);
        expected_output.push_back(hi);
        pc += 2;        
    }

    int passed = 1;
    try {
        PasmTokenizer tokenizer;
        Options options;
        options.verbose = false;
        std::unordered_map<std::string, MacroDef> macros_;
        std::vector<AnonymousLabel> anonymous_labels;    


        auto tokens = tokenizer.tokenize(source_code, fileid);
        AssemblerParser parser(tokens, options);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);
        MultiPassAssembler assembler(options);
        assembler.Assemble(statements, anonymous_labels, src_mgr);

        std::cout << std::format("{}{} {}PASSED: {:4}", es.column(col), es.ERASE_CURSOR_EOL, 
            es.gr(es.BRIGHT_GREEN_FOREGROUND), passed);

    }
    catch (std::exception& ex) {
        passed = 0;         
    }

    return passed;
}