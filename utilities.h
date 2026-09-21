/**
 * @file getmangledsymbol.h
 * @brief Utilities for local symbol scoping, file tokenization, and relative anonymous label lookup.
 * @author Paul Baxter
 */

#pragma once

#include <algorithm>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

#include "PasmTokenizer.hpp"
#include "ruletype.h"

// Forward declarations
struct SourceManager;
struct AnonymousLabel;

/**
 * @brief Mangles a local label identifier by prefixing it with its parent global scope.
 *
 * Local labels starting with `@` (e.g., `@loop`) are scoped under the most recent global
 * label (`parent_scope`), returning a composite name like `main@loop`. If `parent_scope` is
 * empty or the symbol is not local, the original symbol is returned unchanged.
 *
 * @param symbol The raw symbol or label identifier to evaluate.
 * @param parent_scope The active global label or scope name.
 * @return std::string The mangled symbol string if local and in scope; otherwise, the original symbol.
 */
inline std::string GetMangledSymbol(const std::string& symbol, const std::string& parent_scope) {
    if (symbol.starts_with('@')) {
        // If a local label appears before any global label, fall back to raw name
        return parent_scope.empty() ? symbol : parent_scope + symbol;
    }
    return symbol;
}

/**
 * @brief Loads a source file, registers it with the SourceManager, and tokenizes its contents.
 *
 * @param filepath Path to the source file on disk.
 * @param src_mgr Reference to the active SourceManager tracking open files and line buffers.
 * @param tokenizer Lexer instance used to tokenize the source code text.
 * @return std::vector<PasmTokenizer::Token> Sequence of generated tokens for the target file.
 */
std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
);

/**
 * @brief Resolves a relative anonymous label ('+' or '-') offset relative to the program counter.
 *
 * @param anonymous_labels Collection of sorted anonymous labels registered during assembly.
 * @param forward Search direction: true for forward targets ('+'), false for backward targets ('-').
 * @param count Relative target instance offset (e.g., 2 for '++' or '--').
 * @param pc Current program counter location.
 * @return std::optional<int> Target address if resolved; std::nullopt if the label reference cannot be satisfied.
 */
std::optional<int> FindAnonLabel(
    const std::vector<AnonymousLabel>& anonymous_labels,
    bool forward,
    int count,
    uint16_t pc
);
