/**
 * @file utilities.cpp
 * @brief Utility functions for file loading, tokenization, and relative anonymous label resolution.
 * @author Paul Baxter
 */

#include "utilities.h"

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

std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
) {
    src_mgr.PushInclude(filepath);

    struct IncludeGuard {
        SourceManager& mgr;
        ~IncludeGuard() { mgr.PopInclude(); }
    } guard{src_mgr};

    int fileid = src_mgr.GetOrRegisterFile(filepath);

    std::ifstream infile(filepath);
    if (!infile.is_open()) {
        std::cerr << std::format("Error: Unable to open file {}\n", filepath);
        return {};
    }

    int lineNo = 1;
    std::string line;
    std::string source_code;

    while (std::getline(infile, line)) {
        src_mgr.source[{fileid, lineNo}] = line;
        source_code.append(line).append("\n");
        lineNo++;
    }

    return tokenizer.tokenize(source_code, fileid);
}

std::optional<int> FindAnonLabel(
    const std::vector<AnonymousLabel>& anonymous_labels,
    bool forward,
    int count,
    uint16_t pc
) {
    if (anonymous_labels.empty()) {
        return std::nullopt;
    }

    // Binary search to find boundary around 'pc'
    size_t lo = 0;
    size_t hi = anonymous_labels.size();

    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (anonymous_labels[mid].address <= pc) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }

    size_t start_index = lo;
    int found_count = 0;

    if (forward) {
        for (size_t i = start_index; i < anonymous_labels.size(); ++i) {
            if (anonymous_labels[i].type == '+') {
                if (++found_count == count) {
                    return anonymous_labels[i].address;
                }
            }
        }
    } else {
        if (start_index == 0) {
            return std::nullopt;
        }

        // Loop downward safely using unsigned indices
        for (size_t i = start_index; i > 0; --i) {
            size_t back_index = i - 1;
            if (anonymous_labels[back_index].type == '-') {
                if (++found_count == count) {
                    return anonymous_labels[back_index].address;
                }
            }
        }
    }

    return std::nullopt;
}