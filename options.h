/**
 * @file options.h
 * @brief Configuration settings and command-line options for controlling the assembly process.
 * @author Paul Baxter
 */

#pragma once
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

/**
 * @struct Options
 * @brief Holds assembler execution options, input/output paths, and symbol definitions.
 */
struct Options {
    uint16_t start_addr;                                       /**< Starting origin address for code generation (e.g., $C000). */
    std::string outfile;                                       /**< Path to the output binary file. */
    std::vector<std::string> include;                          /**< List of search directory paths for included files. */
    std::vector<std::string> traced_symbols;                   /**< Symbol names selected for active tracing during assembly passes. */
    std::vector<std::string> input_filenames;                  /**< Source file paths to assemble. */
    std::vector<std::pair<std::string, int>> defined_symbols;  /**< Pre-defined symbol names and integer values passed via CLI. */
    bool c64 = false;                                          /**< Flag indicating whether to generate Commodore 64 executable output (PRG format with 2-byte load address header). */
    bool verbose = false;                                      /**< Enables verbose diagnostic logging during lexing, parsing, and assembly. */
    bool warnings = true;                                      /**< Enables warning reporting during assembly. */
    bool ignore_size = true;                                   /**< Flag to ignore memory range/size boundary errors. */
};
