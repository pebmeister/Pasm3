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
#include <fstream>

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
	std::string outfile;
    std::vector<std::string>input_filenames;
    auto arg = 1;
	bool c64 = false;
	
    while(arg < argc) {
		std::string arg_str = std::string(argv[arg]);
        if (arg_str[0] != '-') {
            input_filenames.push_back(argv[arg]);
        }
		else if (arg_str == "-o") {
			arg++;
			if (arg >= argc) {
				std::cout << "invalid output file\n";
				return -1;
			}
			outfile = argv[arg];
		}
		else if (arg_str == "-c64") {
			c64 = true;
		}
		else {	
			std::cout << "Unknown option '" << arg_str << "'\n";
			return -1;
		}
		arg++;
    }
	
    if (input_filenames.empty()) {
        std::cout << "No input file specified.\n";
        return 1;
    }

 
    try {
		std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

		SourceManager src_mgr;
		PasmTokenizer tokenizer;
		std::unordered_map<std::string, MacroDef> macros_;
		std::vector<AnonymousLabel> anonymous_labels;
		std::vector<PasmTokenizer::Token> tokens;
		
		for (const auto& root_file : input_filenames) {
			auto file_tokens = LoadAndTokenizeFile(root_file, src_mgr, tokenizer);
			tokens.insert(tokens.end(), file_tokens.begin(), file_tokens.end());
		}

        AssemblerParser parser(tokens);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);

        MultiPassAssembler assembler(0xC000);
        assembler.Assemble(statements, anonymous_labels, src_mgr);
        std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();

        std::cout << assembler.listing_file << "\n";
		
		if (outfile.length() > 0) {
			std::ofstream out(outfile, std::ios::out | std::ios::binary);
			auto sz = assembler.binary_output.size();
			if (c64) {
				auto lo = static_cast<unsigned char>(assembler.load_address & 0xFF); 
				auto hi = static_cast<unsigned char>((assembler.load_address >> 8) & 0xFF); 
				out.write(reinterpret_cast<const char*>(&lo), sizeof(unsigned char));
				out.write(reinterpret_cast<const char*>(&hi), sizeof(unsigned char));
				sz += 2;
			}
			out.write(reinterpret_cast<const char*>(assembler.binary_output.data()), assembler.binary_output.size());
			out.close();
			
			std::cout << "Wrote " << sz << " bytes to " << outfile << "\n";
		}		
	}
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
    }
    return 0;
}
