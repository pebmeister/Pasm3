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
#include "parseargs.h"

/**
 * @brief Application entry point for the 6502 cross-assembler.
 * 
 * Manages the high-level workflow of the assembly pipeline:
 * - Parses command-line arguments and determines output filenames.
 * - Tokenizes source files and generates intermediate statements.
 * - Executes multi-pass assembly to resolve symbols and output machine code.
 * - Handles optional C64 PRG header prepending and file output writing.
 * - Executes post-processing steps (VICE symbol exports, D64 image creation, 
 *   cartridge conversion via cartconv, and launching VICE emulator sessions).
 * 
 * @param argc Count of command-line arguments.
 * @param argv Array of command-line argument strings.
 * @return int Returns 0 on successful assembly and post-processing, or 1 on runtime errors.
 */
int main(int argc, char* argv[])
{
    try {
        /// Parse and validate command-line options.
        Options options = parse_args(argc, argv);

        /// Resolve the base filename (excluding file extensions) used for output generation.
        std::string fname = options.out ? options.outfile : options.input_filenames[0];
        std::string base_name = RemoveExtension(fname);

        /// Start high-precision execution timer for performance metrics.
        std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
        
        /// Initialize assembly tracking structures, state buffers, and parser tokens.
        SourceManager src_mgr;                               /// Tracks source file origins, include depths, and line positions.
        PasmTokenizer tokenizer;                             /// Lexical analyzer context for PASM input files.

        std::vector<PasmTokenizer::Token> tokens;            /// Aggregated token stream from all source inputs.
        
        /// Tokenize each input source file sequentially into a unified token stream.
        for (const auto& root_file : options.input_filenames) {
            auto file_tokens = LoadAndTokenizeFile(root_file, src_mgr, tokenizer);
            tokens.insert(tokens.end(), file_tokens.begin(), file_tokens.end());
        }

        /// Parse the accumulated token stream into executable AST statements.
        AssemblerParser parser(tokens, options, src_mgr);
        auto statements = parser.ParseProgram(tokenizer);

        /// Execute multi-pass assembly to resolve addresses, symbols, and output bytecode.
        MultiPassAssembler assembler(options, src_mgr);
        assembler.Assemble(statements);
        std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();

        /// Print assembly listing file path if verbose output is requested.
        if (options.verbose) {
            std::cout << assembler.listing_file << "\n";
        }

        /// Print symbol table cross refrence.
        if (options.xref) {
            std::cout << assembler.ExrefSymbols();
        }
        
        /// Handle primary binary file generation.
        if (options.out) {
            /// Prepend Commodore 64 2-byte PRG load address header (little-endian) if targeting C64.
            if (options.c64) {
                auto lo = static_cast<uint8_t>(assembler.load_address & 0xFF); 
                auto hi = static_cast<uint8_t>((assembler.load_address >> 8) & 0xFF); 
                uint8_t prefix[2] = {lo, hi};

                assembler.binary_output.insert(assembler.binary_output.begin(), std::begin(prefix), std::end(prefix));
            }

            /// Stream assembled bytecode array directly to disk.
            std::ofstream out(options.outfile, std::ios::out | std::ios::binary);
            auto sz = assembler.binary_output.size();
            out.write(reinterpret_cast<const char*>(assembler.binary_output.data()), sz);
            out.close();
            
            std::cout << std::format("Wrote {} bytes to {}.\n", sz, options.outfile);
        }        
        
        /// Report total assembly execution time.
        std::chrono::duration<double> elapsed_seconds = end - begin;
        std::cout << std::format("Elapsed time: {} seconds.\n", elapsed_seconds.count());

        /// Convert assembled binary into a Commodore CRT cartridge image using the external 'cartconv' tool.
        if (options.cart) {
            std::string command = std::format("cartconv -i {} -l {} {} -o {}.crt",
                options.outfile, assembler.load_address, options.cart_options, base_name);
            std::cout << command << "\n";
            int exitCode = std::system(command.c_str());
            
            if (exitCode != 0) {
                throw std::runtime_error(std::format("Error running {}", command.c_str()));
            }
        }

        /// Construct or update a Commodore D64 disk image with the generated PRG binary and optional loader.
        if (options.d64) {
            d64 disk;
            auto name = GetUppercaseBasename(options.outfile);

            /// Prepend an automatic BASIC loader PRG file to launch the main binary if requested.
            if (options.autoloader) {
                auto loader_code = CreateAutoLoader(name, assembler.load_address);
                disk.addFile("LOADER", c64FileType(d64FileTypes::PRG), loader_code);
                std::cout << std::format("Added LOADER.PRG to disk {}\n", options.d64_diskname);
            }
            
            disk.addFile(name, c64FileType(d64FileTypes::PRG), assembler.binary_output);
            disk.save(options.d64_diskname);
            std::cout << std::format("Added {}.PRG to disk {}\n", name, options.d64_diskname);
        }

        /// Export symbol table for VICE/C64 debugger compatibility.
        if (options.vs) {
            auto syms = assembler.ExportSymbols();
            std::ofstream out(options.vs_name, std::ios::out);
            out << syms;            
            std::cout << std::format("Created {}\n", options.vs_name);            
        }

        /// Generate VICE monitor breakpoint script (.mon) and launch debugging session in x64sc.
        if (options.debug) {
            auto name = base_name + ".mon";
            std::ofstream out(name, std::ios::out);
            if (options.vs) {
                out << std::format("load_labels \"{}\"\n", options.vs_name);
            }
            
            /// Offset entry breakpoint past cartridge header if targeting CRT format.
            auto load_address = options.cart ? assembler.load_address + 9 : assembler.load_address;
            out << std::format("break {:04X}\n", load_address);
            out.close();  
            std::cout << std::format("Created {}\n", name);

            /// Construct VICE execution command specifying monitor command script and target image.
            std::string command = std::format("x64sc.exe -moncommands {} ", name);
            if (options.d64) {
                command += options.d64_diskname;
            }
            else if (options.cart) {
                command += std::format("-cartcrt {}.crt", base_name);
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

        /// Launch the assembled executable or disk/cartridge target directly in the VICE x64sc emulator.
        if (options.launch) {
            std::string command = std::format("x64sc.exe ");
            if (options.d64) {
                command += options.d64_diskname;
            }
            else if (options.cart) {
                command += std::format("-cartcrt {}.crt", base_name);
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
    /// Catch and log assembly and post-processing exceptions.
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
        return 1;
    }
    return 0;
}
