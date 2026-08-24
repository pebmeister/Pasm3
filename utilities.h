#pragma once
#include <fstream>
#include <algorithm>
#include "PasmTokenizer.hpp"


inline std::string GetMangledSymbol(const std::string& symbol, const std::string& parent_scope) {
    if (symbol.starts_with('@')) {
        // If a local label appears before any global label, fall back to raw name
        return parent_scope.empty() ? symbol : parent_scope + symbol;
    }
    return symbol;
}


inline std::string read_file_to_string(const std::string& path) {
    std::ifstream file(path, std::ios::binary);
    if (!file) throw std::runtime_error("Failed to open file: " + path);

    std::ostringstream ss;
    ss << file.rdbuf();          // reads entire file
    return ss.str();
}

std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
);
std::optional<int> FindAnonLabel(const std::vector<AnonymousLabel>& anonymous_labels,  bool forward, int count, uint16_t pc);




