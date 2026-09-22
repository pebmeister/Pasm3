/**
 * @file main.cpp
 * @brief Main entry point for the PASM 6502 multi-pass assembler CLI tool.
 * @author Paul Baxter
 * @details Handles command-line option parsing, source loading, tokenization,
 *          parsing, multi-pass binary assembly, and binary/PRG output generation.
 */

#include <chrono>
#include <exception>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

#define GEN_RULEMAP
#include "ruletype.h"
#undef GEN_RULEMAP

#define GEN_TOKMAP
#include "tokenkind.h"
#undef GEN_TOKMAP

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "macrodef.h"

/**
 * @brief prints help message.
 * 
 */
void help()
{
    std::cout <<
R"(Usage: 
    pasm3 [-o outfile] [-c64] [-i directory] [-st symbol] [-d symbol value] [-h] inputfile inputfile2 ...

    -h                  Print help.
    -o outfile          Specifies the output file name.
    -c64                Specifies Commodore64 program format. 
                        It places the load address in first two bytes.
    -i directory        Specifies include directory. Can be specified more than once.
    -st symbol          Specifies symbol trace. Displays symbol and value and when modified.
                        This can change because of macros etc. 
                        Can be specified multiple times.
    -d symbol value     Defines a symbol and value.
                        Can be specified more than once.
)";
}

/**
 * @brief Parses the input arguments.
 * 
 * Parses CLI flags (`-o`, `-c64`, `-i`, `-st`, `-d`)
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return int Returns Options on successful assembly
 * @exception throws runtime excpeption on invalid parameters
 */
Options parse_args(int argc, char* argv[])
{
    Options options;
    auto arg = 1;
    
    while (arg < argc) {
        std::string arg_str = std::string(argv[arg]);        
        if (arg_str[0] != '-') {
            options.input_filenames.push_back(argv[arg]);
        }
        else if (arg_str == "-h") {
            help();
            exit(0);
        }
        else if (arg_str == "-o") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No output file specified for -o");
            }
            options.outfile = argv[arg];
        }
        else if (arg_str == "-c64") {
            options.c64 = true;
        }
        else if (arg_str == "-i") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No directory specified for -i");
            }
            options.include.push_back(argv[arg]);
        }
        else if (arg_str == "-st") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No symbol defined for -st");
            }
            options.traced_symbols.push_back(argv[arg]);
        }
        else if (arg_str == "-d") {
            arg++;
            if ((arg + 1) >= argc) {
                help();
                throw std::runtime_error("No symbol or value defined for -d");
            }
            std::string sym = argv[arg];
            arg++;
            std::string val = argv[arg];
            int symval;
            std::stringstream ss;
            if (val[0] == '$') {
                ss << std::hex << val.substr(1);
            }
            else {
                ss << std::dec << val;
            }
            ss >> symval;
            options.defined_symbols.push_back({sym, symval});
        }
        else { 
            help();
            throw std::runtime_error(std::format("Unknown option '{}'", arg_str));
        }
        arg++;
    }
    
    if (options.input_filenames.empty()) {
        help();
        throw std::runtime_error("No input file specified");
    }
    return options;
}

/**
 * @brief Application entry point for the 6502 cross-assembler.
 * 
 * tokenizes and parses code statements, builds symbol tables over multiple
 * passes, and outputs binary files and listings.
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return int Returns 0 on successful assembly, or non-zero on invalid usage or runtime exceptions.
 */
int main(int argc, char* argv[])
{
    try {
        Options options = parse_args(argc, argv);

        std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

        SourceManager src_mgr;
        PasmTokenizer tokenizer;
        std::unordered_map<std::string, MacroDef> macros_;
        std::vector<AnonymousLabel> anonymous_labels;
        std::vector<PasmTokenizer::Token> tokens;
        
        for (const auto& root_file : options.input_filenames) {
            auto file_tokens = LoadAndTokenizeFile(root_file, src_mgr, tokenizer);
            tokens.insert(tokens.end(), file_tokens.begin(), file_tokens.end());
        }

        AssemblerParser parser(tokens, options);
        auto statements = parser.ParseProgram(src_mgr, macros_, tokenizer);

        MultiPassAssembler assembler(options);
        assembler.Assemble(statements, anonymous_labels, src_mgr);
        std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();

        std::cout << assembler.listing_file << "\n";
        
        if (options.outfile.length() > 0) {
            std::ofstream out(options.outfile, std::ios::out | std::ios::binary);
            auto sz = assembler.binary_output.size();
            if (options.c64) {
                auto lo = static_cast<unsigned char>(assembler.load_address & 0xFF); 
                auto hi = static_cast<unsigned char>((assembler.load_address >> 8) & 0xFF); 
                out.write(reinterpret_cast<const char*>(&lo), sizeof(unsigned char));
                out.write(reinterpret_cast<const char*>(&hi), sizeof(unsigned char));
                sz += 2;
            }
            out.write(reinterpret_cast<const char*>(assembler.binary_output.data()), assembler.binary_output.size());
            out.close();
            
            std::cout << "Wrote " << sz << " bytes to " << options.outfile << "\n";
        }       
        std::chrono::duration<double> elapsed_seconds = end - begin;
        std::cout << "Elapsed time: " << elapsed_seconds.count() << " seconds\n";
    }
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
    }
    return 0;
}