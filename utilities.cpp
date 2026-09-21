/**
 * @file assembler_utils.cpp
 * @brief Utility functions for file loading, tokenization, and relative anonymous label resolution.
 * @author Paul Baxter
 */

#include <chrono>
#include <exception>
#include <format>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stack>
#include <utility>

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "getmangledsymbol.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "opcodedict.h"
#include "opcodeinfo.h"
#include "sourceManager.h"
#include "symboltable.h"
#include "utilities.h"

/**
 * @brief Loads a source file, tracks line numbers in the source manager, and tokenizes its contents.
 *
 * Manages the include stack via SourceManager, populates line-by-line source mappings
 * for diagnostics and listing outputs, and tokenizes the accumulated file buffer.
 *
 * @param filepath Path to the source file on disk.
 * @param src_mgr Reference to the active SourceManager tracking files and includes.
 * @param tokenizer Lexer instance used to tokenize the source code text.
 * @return std::vector<PasmTokenizer::Token> Sequence of generated tokens for the target file.
 */
std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
) {
    src_mgr.PushInclude(filepath);
    int fileid = src_mgr.GetOrRegisterFile(filepath);

    int lineNo = 1;
    std::string line;
    std::string source_code;
    std::ifstream infile(filepath);
    while (std::getline(infile, line)) {
        src_mgr.source[{fileid, lineNo}] = line;
        source_code += (line + "\n");
        lineNo++;
    }
    infile.close();

    auto filetokens = tokenizer.tokenize(source_code, fileid);

    src_mgr.PopInclude();
    return filetokens;
}

/**
 * @brief Resolves a relative anonymous label address ('+' or '-') relative to the current PC.
 *
 * Employs binary search to find the insertion boundary for the program counter (`pc`),
 * then scans forward or backward to locate the Nth occurrence (`count`) of a '+' or '-' label.
 *
 * @param anonymous_labels Collection of sorted anonymous labels registered during assembly.
 * @param forward Search direction: true for forward targets ('+'), false for backward targets ('-').
 * @param count Relative target instance count (e.g., 2 for '++' or '--').
 * @param pc Current program counter location.
 * @return std::optional<int> Target address if resolved; std::nullopt if the label reference cannot be satisfied.
 */
std::optional<int> FindAnonLabel(
    const std::vector<AnonymousLabel>& anonymous_labels,
    bool forward,
    int count,
    uint16_t pc
) {
    auto sz = anonymous_labels.size();
    if (sz == 0) {
        return std::nullopt;
    }

    // 1. Binary search to find the first label strictly AFTER the current pc.
    size_t lo = 0;
    size_t hi = sz;

    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2; // Corrected midpoint calculation
        if (anonymous_labels[mid].address <= pc) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }

    // 'lo' is now the index of the first anonymous label after the current PC.
    size_t start_index = lo;
    int found_count = 0;

    // 2. Scan in the requested direction
    if (forward) {
        // Searching forward: start from 'start_index' and scan to the end
        while (start_index < sz) {
            auto& lbl = anonymous_labels[start_index];

            if (lbl.type == '+') {
                found_count++;
                if (found_count == count) {
                    return lbl.address;
                }
            }
            start_index++;
        }
    } else {
        // Searching backward: start from 'start_index - 1' and scan down to 0
        if (start_index == 0) {
            return std::nullopt; // No labels exist before the PC
        }

        size_t back_index = start_index - 1;

        while (true) {
            auto& lbl = anonymous_labels[back_index];

            if (lbl.type == '-') {
                found_count++;
                if (found_count == count) {
                    return lbl.address;
                }
            }

            if (back_index == 0) break; // Reached the beginning
            back_index--;
        }
    }

    return std::nullopt;
}
