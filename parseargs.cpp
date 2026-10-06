/**
 * @file parseargs.cpp
 * @author Paul Baxter
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
 * @brief Prints help message.
 */
void help()
{
    std::cout <<
R"(Usage: 
    pasm3 [-h] [-o outfile] [-v] [-vs symfile] [-c64] [-i directory] [-st symbol] [-d symbol value] [-cart [options]] [-d64 disk] [-al] [-debug] [-launch] [-mp maxpass] [-xref] inputfile inputfile2 ...

    -h                  Print help.
    -o [outfile]        Specifies to create an output file.
    -v                  Specifies verbose output.
    -vs [file]          Create VICE symbol file.
    -c64                Specifies Commodore 64 program format. 
                        It places the load address in first two bytes.
    -i directory        Specifies include directory. Can be specified more than once.
    -st symbol          Specifies symbol trace. Displays symbol and value and when modified.
                        Can be specified multiple times.
    -d symbol value     Defines a symbol and value.
                        Can be specified more than once.
    -cart [options]     Runs cartconv on the outputfile with the specified options enclosed in quotes.
                        Load address and inputname are auto specified.
                        VICE must be installed and in the path.
    -d64 [diskname]     Creates d64 disk and installs the output file.
    -al                 Creates auto loader. This will also create a .d64 disk if -d64 is not specified.
    -debug              Launch VICE monitor and debug. Can not be used with -launch.
    -launch             Launch in VICE. Can not be used with -debug.
    -mp maxpass         Sets the max number of passes. Default is 10.
    -xref               Display a cross refrerence symbol file.
)";
}

/**
 * @brief Parses the input arguments.
 * 
 * Parses CLI flags (`-h`, `-o`, `-debug`, `-v`, `-c64`, `-vs`, `-i`, `-st`, `-d`, `-cart`, `-d64`, `-al`, `-launch`, `-mp`, `-xref`)
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return Options Returns Options on successful parsing.
 * @exception throws runtime_error on invalid parameters
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
            options.out = true;

            if ((arg + 1) < argc && argv[arg + 1][0] != '-') {
                options.outfile = argv[++arg];
            }
        }
        else if (arg_str == "-c64") {
            options.c64 = true;
        }
        else if (arg_str == "-vs") {
            options.vs = true;
            if ((arg + 1) < argc && argv[arg + 1][0] != '-') {
                options.vs_name = argv[++arg];
            }
        }
        else if (arg_str == "-mp") {
            if ((arg + 1) >= argc) {
                help();
                throw std::runtime_error("Max pass value not specified for -mp");
            }
            arg++;
            options.max_pass = std::stoi(argv[arg]);
            if (options.max_pass <= 1) {
                help();
                throw std::runtime_error("Invalid value specified for -mp (must be > 1)");
            }
        }
        else if (arg_str == "-al") {
            options.autoloader = true;
        }
        else if (arg_str == "-i") {
            if ((arg + 1) >= argc) {
                help();
                throw std::runtime_error("No directory specified for -i");
            }
            options.include.push_back(argv[++arg]);
        }
        else if (arg_str == "-cart") {
            options.cart = true;
            if ((arg + 1) >= argc || argv[arg + 1][0] == '-') {
                options.cart_options = "-t normal -p";
            }
            else {
                options.cart_options = argv[++arg];
            }
        }
        else if (arg_str == "-d64") {
            options.d64 = true;

            if ((arg + 1) < argc && argv[arg + 1][0] != '-') {
                options.d64_diskname = argv[++arg];
            }
        }
        else if (arg_str == "-st") {
            if ((arg + 1) >= argc) {
                help();
                throw std::runtime_error("No symbol defined for -st");
            }
            options.traced_symbols.push_back(argv[++arg]);
        }
        else if (arg_str == "-launch") {
            options.launch = true;
        }
        else if (arg_str == "-xref") {
            options.xref = true; // Fixed typo (xfref -> xref)
        }
        else if (arg_str == "-d") {
            // Needs two trailing parameters: symbol name and value
            if ((arg + 2) >= argc) {
                help();
                throw std::runtime_error("No symbol or value defined for -d");
            }
            std::string sym = argv[++arg];
            std::string val = argv[++arg];
            
            int symval = 0;
            std::stringstream ss;
            if (!val.empty() && val[0] == '$') {
                ss << std::hex << val.substr(1);
            }
            else {
                ss << std::dec << val;
            }
            
            if (!(ss >> symval)) {
                help();
                throw std::runtime_error(std::format("Invalid numeric value '{}' for symbol '{}'", val, sym));
            }
            
            options.defined_symbols.push_back({sym, symval});
        }
        else { 
            help();
            throw std::runtime_error(std::format("Unknown option '{}'", arg_str));
        }
        arg++;
    }
  
    if (options.launch && options.debug) {
        help();
        throw std::runtime_error("Launch cannot be used with debug");
    }

    if (options.input_filenames.empty()) {
        help();
        throw std::runtime_error("No input file specified");
    }

    std::string fname = options.out ? options.outfile : options.input_filenames[0];
    std::string base_name = RemoveExtension(fname);
    
    if (!options.out && (options.cart || options.launch || options.debug || options.d64 || options.autoloader)) {
        options.out = true;
    }
    
    if (options.out && options.outfile.empty()) {
        if (options.cart) {
            options.outfile = std::format("{}.bin", base_name);        
        }
        else {
            options.outfile = std::format("{}{}", base_name, (options.c64 ? ".prg" : ".bin"));        
            if (options.autoloader) {
                namespace fs = std::filesystem;
                fs::path p(fname);
                
                // Get just the uppercase filename without path or extension (e.g., "MYCODE")
                auto prg_name = GetBasename(fname);
                
                // Rebuild the output path cleanly in the same directory with the uppercase name
                options.outfile = (p.parent_path() / (prg_name + ".prg")).string();
            }
        }
    }
    
    if (options.autoloader && !options.d64) {
        options.d64 = true;
    }
    if (options.debug && !options.vs) {
        options.vs = true;
    }
    if (options.d64 && options.d64_diskname.empty()) {
        options.d64_diskname = std::format("{}.d64", base_name);        
    }
    if (options.vs && options.vs_name.empty()) {
        options.vs_name = std::format("{}.vs", base_name);        
    }

    return options;
}
