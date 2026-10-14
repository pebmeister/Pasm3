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

std::vector<uint8_t> read_binary_file(const std::string& filepath) 
{
    // 1. Open file at the end to get file size immediately
    std::ifstream file(filepath, std::ios::binary | std::ios::ate);
    
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open binary file: " + filepath);
    }

    std::streamsize file_size = file.tellg();
    
    // Check for empty file
    if (file_size <= 0) {
        return {};
    }

    // 2. Allocate memory ahead of time
    std::vector<uint8_t> buffer(static_cast<size_t>(file_size));

    // 3. Move cursor back to beginning and read into buffer
    file.seekg(0, std::ios::beg);
    if (!file.read(reinterpret_cast<char*>(buffer.data()), file_size)) {
        throw std::runtime_error("Failed to read binary content from: " + filepath);
    }

    return buffer;
}