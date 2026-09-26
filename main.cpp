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
#include <filesystem>
#include <format> // <-- Added for std::format
#include <cctype>

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
#include "d64.h"
#include "autoloader.h"

/**
 * @brief get the uppercase base name from a path.
 *
 * Used to create a Commodore 64 file name 
 */
std::string GetUppercaseBasename(const std::string& filepath) {
    namespace fs = std::filesystem;
    
    // 1. Strip directory and extension
    std::string name = fs::path(filepath).filename().stem().string();
    
    // 2. Convert to uppercase
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    
    return name;
}

/**
 * @brief prints help message.
 */
void help()
{
    std::cout <<
R"(Usage: 
    pasm3 [-o outfile] [-c64] [-d64 disk] [-al] [-i directory] [-st symbol] [-d symbol value] [-h] [-cart options] inputfile inputfile2 ...

    -h                  Print help.
    -o outfile          Specifies the output file name.
    -v                  Specifies verbose output.
    -c64                Specifies Commodore 64 program format. 
                        It places the load address in first two bytes.
    -i directory        Specifies include directory. Can be specified more than once.
    -st symbol          Specifies symbol trace. Displays symbol and value and when modified.
                        This can change because of macros etc. 
                        Can be specified multiple times.
    -d symbol value     Defines a symbol and value.
                        Can be specified more than once.
    -cart options       Runs cartconv on the outputfile with the specified options enclosed in quotes
                        load address and inputname are auto specified.
                        VICE must be installed and in the path.
                        -o outfile MUST be specified
    -d64 disk           Creates d64 disk and installs the output file
                        -o outfile MUST be specified
    -al                 Creates auto loader. Can only be used with -d64
                        -o outfile MUST be specified
)";
}

/**
 * @brief Parses the input arguments.
 * 
 * Parses CLI flags (`-h`, `-o`, `-v`, `-c64`, `-i`, `-st`, `-d`, `-cart`, `-d64`)
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return Options Returns Options on successful assembly
 * @exception throws runtime exception on invalid parameters
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
        else if (arg_str == "-v") {
            options.verbose = true;
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
        else if (arg_str == "-al") {
            options.autoloader = true;
        }
        else if (arg_str == "-i") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No directory specified for -i");
            }
            options.include.push_back(argv[arg]);
        }
        else if (arg_str == "-cart") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No options specified for -cart"); // Fixed message
            }
            options.cart = true;
            options.cart_options = argv[arg];
        }
        else if (arg_str == "-d64") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No disk name specified for -d64"); // Fixed typo
            }
            options.d64 = true;
            options.d64_diskname = argv[arg];
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
    if (options.cart && options.outfile.length() == 0) {
        help();
        throw std::runtime_error("Outfile must be specified when creating a cart.");
    }
    if (options.d64 && options.outfile.length() == 0) {
        help();
        throw std::runtime_error("Outfile must be specified when creating a d64 disk."); // Added validation
    }
    if (options.autoloader && ! options.d64) {
        help();
        throw std::runtime_error("d64 disk must be specified when creating an autoloader."); // Added validation
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
            if (options.c64) {
                auto lo = static_cast<uint8_t>(assembler.load_address & 0xFF); 
                auto hi = static_cast<uint8_t>((assembler.load_address >> 8) & 0xFF); 
                // The two bytes you want to add to the start
                uint8_t prefix[2] = {lo, hi};

                // Insert the 2 bytes at the beginning of the vector
                assembler.binary_output.insert(assembler.binary_output.begin(), std::begin(prefix), std::end(prefix));
            }

            std::ofstream out(options.outfile, std::ios::out | std::ios::binary);
            auto sz = assembler.binary_output.size();
            out.write(reinterpret_cast<const char*>(assembler.binary_output.data()), assembler.binary_output.size());
            out.close();
            
            std::cout << "Wrote " << sz << " bytes to " << options.outfile << "\n";
        }        
        std::chrono::duration<double> elapsed_seconds = end - begin;
        std::cout << "Elapsed time: " << elapsed_seconds.count() << " seconds\n";

        if (options.cart) {
            std::string command = std::format("cartconv -i {} -l {} {} -o {}.crt", 
                options.outfile, assembler.load_address, options.cart_options, options.outfile);
            std::cout << command << "\n";
            int exitCode = std::system(command.c_str());
            
            if (exitCode != 0) {
                throw std::runtime_error("Error running cart convert");
            }
        }
        if (options.d64) {
            d64 disk;
            auto name = GetUppercaseBasename(options.outfile);

            if (options.autoloader) {
                auto loader_code = CreateAutoLoader(name, assembler.load_address);
                disk.addFile("LOADER", c64FileType(d64FileTypes::PRG), loader_code);
                std::cout << "Added LOADER.PRG to disk " << options.d64_diskname << "\n";
            }
            
            disk.addFile(name, c64FileType(d64FileTypes::PRG), assembler.binary_output);
            disk.save(options.d64_diskname);
            std::cout << "Added " << name << ".PRG to disk " << options.d64_diskname << "\n";
        }
    }
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
    }
    return 0;
}
