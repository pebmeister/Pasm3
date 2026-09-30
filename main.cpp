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
#include <format>
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


std::string RemoveExtension(const std::string filepath) {
    namespace fs = std::filesystem;
    
    fs::path p(filepath);
    p.replace_extension(""); // Clears the extension while keeping directories
    
    return p.string();
}

/**
 * @brief Get the uppercase base name from a path.
 *
 * Used to create a Commodore 64 file name 
 */
std::string GetUppercaseBasename(const std::string& filepath) {
    namespace fs = std::filesystem;
    
    fs::path p(filepath);

    // 1. Strip directory and extension
    std::string name = p.filename().stem().string();
    
    // 2. Convert to uppercase in-place (note name.begin() as the 3rd argument)
    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    
    return name;
}

/**
 * @brief Prints help message.
 */
void help()
{
    std::cout <<
R"(Usage: 
    pasm3 [-h] [-o outfile] [-v] [-vs symfile] [-c64] [-i directory] [-st symbol] [-d symbol value] [-cart options] [-d64 disk] [-al] [-debug] inputfile inputfile2 ...

    -h                 Print help.
    -o outfile         Specifies the output file name.
    -v                 Specifies verbose output.
    -vs file           Create VICE symbol file.
    -c64               Specifies Commodore 64 program format. 
                       It places the load address in first two bytes.
    -i directory       Specifies include directory. Can be specified more than once.
    -st symbol         Specifies symbol trace. Displays symbol and value and when modified.
                       Can be specified multiple times.
    -d symbol value    Defines a symbol and value.
                       Can be specified more than once.
    -cart options      Runs cartconv on the outputfile with the specified options enclosed in quotes
                       load address and inputname are auto specified.
                       VICE must be installed and in the path.
                       -o outfile MUST be specified
    -d64 disk          Creates d64 disk and installs the output file
                       -o outfile MUST be specified
    -al                Creates auto loader. Can only be used with -d64
                       -o outfile MUST be specified
    -debug             Launch VICE monitor and debug
)";
}

/**
 * @brief Parses the input arguments.
 * 
 * Parses CLI flags (`-h`, `-o`, `-debug`, `-v`, `-c64`, `-vs`, `-i`, `-st`, `-d`, `-cart`, `-d64`, `-al`)
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return Options Returns Options on successful parsing.
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
        else if (arg_str == "-debug") {
            options.debug = true;
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
        else if (arg_str == "-vs") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No name specified for -vs");
            }
            options.vs = true;
            options.vs_name = argv[arg];
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
            if (arg >= argc || argv[arg + 1][0] == '-' ) {
                options.cart = true;
                options.cart_options = "-t normal -p";
            }
            else {
                options.cart = true;
                options.cart_options = argv[arg];
                arg++;
            }
        }
        else if (arg_str == "-d64") {
            arg++;
            if (arg >= argc) {
                help();
                throw std::runtime_error("No disk name specified for -d64");
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

    std::string fname = options.outfile;
    if (fname.length() == 0) {
        fname = options.input_filenames[0];
    }

    std::string base_name = RemoveExtension(fname);
    
    if (options.cart && options.outfile.length() == 0) {
        options.outfile = base_name + ".bin";        
    }
    else if (options.outfile.length() == 0) {
        options.outfile = options.c64 ? base_name + ".prg" : base_name + ".bin";        
        if (options.autoloader) {
            namespace fs = std::filesystem;
            fs::path p(fname);
            
            // Get just the uppercase filename without path or extension (e.g., "MYCODE")
            auto upper_name = GetUppercaseBasename(fname);
            
            // Rebuild the output path cleanly in the same directory with the uppercase name
            options.outfile = (p.parent_path() / (upper_name + ".prg")).string();
            
            std::cout << options.outfile << "\n";
        }
    }
    if (options.autoloader && !options.d64) {
        options.d64 = true;
        options.d64_diskname = base_name + ".d64";
    }
    if (options.debug && !options.vs) {
        options.vs = true;
        options.vs_name = base_name + ".vs";
    }
    
    return options;
}

/**
 * @brief Application entry point for the 6502 cross-assembler.
 * 
 * Tokenizes and parses code statements, builds symbol tables over multiple
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

        if (options.verbose) {
            std::cout << assembler.listing_file << "\n";
        }
        
        if (options.outfile.length() > 0) {
            if (options.c64) {
                auto lo = static_cast<uint8_t>(assembler.load_address & 0xFF); 
                auto hi = static_cast<uint8_t>((assembler.load_address >> 8) & 0xFF); 
                uint8_t prefix[2] = {lo, hi};

                assembler.binary_output.insert(assembler.binary_output.begin(), std::begin(prefix), std::end(prefix));
            }

            std::ofstream out(options.outfile, std::ios::out | std::ios::binary);
            auto sz = assembler.binary_output.size();
            out.write(reinterpret_cast<const char*>(assembler.binary_output.data()), sz);
            out.close();
            
            std::cout << "Wrote " << sz << " bytes to " << options.outfile << "\n";
        }        
        std::chrono::duration<double> elapsed_seconds = end - begin;
        std::cout << "Elapsed time: " << elapsed_seconds.count() << " seconds\n";

        if (options.cart) {
            std::string command = std::format("cartconv -i {} -l {} {} -o {}.crt"),
                options.outfile, assembler.load_address, options.cart_options, RemoveExtension(options.outfile);
            std::cout << command << "\n";
            int exitCode = std::system(command.c_str());
            
            if (exitCode != 0) {
                throw std::runtime_error(std::format("Error running {}", command.c_str()));
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
        if (options.vs) {
            auto syms = assembler.ExportSymbols();
            std::ofstream out(options.vs_name, std::ios::out);
            out << syms;            
            std::cout << "Created " << options.vs_name << "\n";            
        }
        if (options.debug) {
            auto name = RemoveExtension(options.outfile) + ".mon";
            std::ofstream out(name, std::ios::out);
            if (options.vs) {
                out << std::format("load_labels \"{}\"\n", options.vs_name);
            }
            if (options.cart)  {
                out << std::format("break {:04X}\n", assembler.load_address + 9);
            }
            else {
                out << std::format("break {:04X}\n", assembler.load_address);
            }
            out.close();
            
            std::cout << "Created " << name << "\n"; // Fixed bug: prints the .mon name instead of vs_name

            std::string command = std::format("x64sc.exe -moncommands {} ", name);
            if (options.d64) {
                command += options.d64_diskname;
            }
            else if (options.cart) {
                command += "-cartcrt " + RemoveExtension(options.outfile) + ".crt";
            }
            else {                
                command += options.outfile;
            }
            std::cout << command << "\n";
            int exitCode = std::system(command.c_str());            
            if (exitCode != 0) {
                throw std::runtime_error(std::format("Error running {}", command.c_str()));
            }            
        }
    }
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
        return 1;
    }
    return 0;
}
