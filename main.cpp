// Written by Paul Baxter

#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <map>
#include <unordered_map>
#include <cstdint>
#include <cctype>
#include <optional>
#include <algorithm>
#include <iomanip>
#include <sstream>
#include <utility>
#include <format>
#include <fstream>
#include <sstream>
#include <exception>
#include <stack>
#include <chrono>

#define GEN_RULEMAP
#include "ruletype.h"
#undef GEN_RULEMAP

#define GEN_TOKMAP
#include "tokenkind.h"
#undef GEN_TOKMAP

#include "opcodedict.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "multipassassembler.h"
#include "symboltable.h"
#include "sourceManager.h"

#include "getmangledsymbol.h"
#include "opcodeinfo.h"

#include "exprNode.h"
#include "macrodef.h"
#include "utilities.h"
#include "AssemblerParser.h"

int main(int argc, char* argv[])
{
	SourceManager src_mgr;
	PasmTokenizer tokenizer;
	std::unordered_map<std::string, MacroDef> macros_;
	std::vector<AnonymousLabel> anonymous_labels;

    std::vector<std::string>input_filenames;
    auto arg = 1;
    while(arg < argc) {
        if (argv[arg][0] != '-') {
            input_filenames.push_back(argv[arg]);
            arg++;
        }
        else {
            std::cout << "Unknown option " << argv[arg] << "\n";
            return -1;
        }
    }
    if (input_filenames.empty()) {
        std::cout << "No input file specified.\n";
        return 1;
    }

    std::vector<PasmTokenizer::Token> tokens;

    for (const auto& root_file : input_filenames) {
        auto file_tokens = LoadAndTokenizeFile(root_file, src_mgr, tokenizer);
        tokens.insert(tokens.end(), file_tokens.begin(), file_tokens.end());
    }

    try {

        std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
        AssemblerParser parser(tokens);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);

        MultiPassAssembler assembler(0xC000);
        assembler.Assemble(statements, anonymous_labels, src_mgr);
        std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
        std::cout << "Elapsed " << std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count() / 1000000.0 << " seconds." << std::endl;
    }
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
    }
    return 0;
}
