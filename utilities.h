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


std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
);
std::optional<int> FindAnonLabel(const std::vector<AnonymousLabel>& anonymous_labels,  bool forward, int count, uint16_t pc);




