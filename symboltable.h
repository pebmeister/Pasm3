/**
 * @file symboltable.h
 * @brief Case-insensitive symbol table with tracing support for assembler addresses and constants.
 * @author Paul Baxter
 */

#pragma once

#include <filesystem>
#include <format>
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <set>

#include "sourceManager.h"

    
/**
 * @class SymbolTable
 * @brief Case-insensitive lookup table for mapping identifiers to 16-bit address or integer values.
 *
 * Supports transparent string view lookup, case-insensitive FNV-1a hashing, and active symbol
 * tracing/logging upon definition or modification.
 */
class SymbolTable {
private:
    struct SymbolEntry {
        uint16_t value;
        std::pair<int, int> defined;
        std::vector<std::pair<int, int>> usage;
        
        SymbolEntry(uint16_t v, std::pair<int, int> loc) : value(v), defined(loc) {}
    };

    std::string tablename; /**< Descriptive label for identifying this table instance in debug logs. */

    /**
     * @struct CaseInsensitiveHash
     * @brief Transparent hasher using the 64-bit FNV-1a algorithm on lowercase character codes.
     */
    struct CaseInsensitiveHash {
        using is_transparent = void; /**< Enables transparent heterogeneous lookup via std::string_view. */

        /**
         * @brief Computes a case-insensitive 64-bit FNV-1a hash of a string view.
         * @param sv The string view to hash.
         * @return The calculated 64-bit hash value.
         */
        std::size_t operator()(std::string_view sv) const {
            std::size_t hash = 14695981039346656037ULL; // FNV-1a 64-bit offset basis
            for (char c : sv) {
                auto uc = static_cast<unsigned char>(c);
                hash ^= static_cast<std::size_t>(std::tolower(uc));
                hash *= 1099511628211ULL; // FNV-1a 64-bit prime
            }
            return hash;
        }
    };

    /**
     * @struct CaseInsensitiveEqual
     * @brief Transparent equality predicate performing case-insensitive string comparison.
     */
    struct CaseInsensitiveEqual {
        using is_transparent = void; /**< Enables transparent heterogeneous comparison via std::string_view. */

        /**
         * @brief Compares two string views for equality, ignoring character case.
         * @param lhs The left-hand string view operand.
         * @param rhs The right-hand string view operand.
         * @return true if the string lengths and lowercase character sequences match; false otherwise.
         */
        bool operator()(std::string_view lhs, std::string_view rhs) const {
            if (lhs.size() != rhs.size()) return false;
            return std::equal(
                lhs.begin(), lhs.end(),
                rhs.begin(),
                [](unsigned char a, unsigned char b) {
                    return std::tolower(a) == std::tolower(b);
                }
            );
        }
    };

    /**
     * @brief Case-insensitive unordered hash map storing symbol names and 16-bit values.
     */
    std::unordered_map<
        std::string,
        SymbolEntry,
        CaseInsensitiveHash,
        CaseInsensitiveEqual
    > symbols_;

    std::unordered_set<std::string> trace_syms_; /**< Set of symbol identifiers actively configured for tracing. */
    SourceManager src_mgr;
    
public:
    bool use_all_symbols = false;
    
    /**
     * @brief Constructs a SymbolTable instance with a specific table name.
     * @param name Descriptive label used in diagnostic trace output.
     */
    explicit SymbolTable(std::string name, const SourceManager& srcm) : tablename(std::move(name)), src_mgr(srcm) {
    }

    /**
     * @brief Enables diagnostic tracing for a specified symbol name.
     * @param name The symbol name to add to the trace watchlist.
     */
    void Trace(const std::string& name) {
        trace_syms_.insert(name);
    }

    /**
     * @brief Disables diagnostic tracing for a specified symbol name.
     * @param name The symbol name to remove from the trace watchlist.
     */
    void Untrace(const std::string& name) {
        trace_syms_.erase(name);
    }

    /**
     * @brief Clears all symbol entries from the table.
     */
    void clear() {
        symbols_.clear();
    }
    
    /**
     * @brief Clears all symbol usage from the table.
     * Shoul be done before every pass
     */
    void reset_usage() {
        for (auto& [_, entry] : symbols_) {
            entry.usage.clear();
        }        
    }
    
    /**
     * @brief Exports the symbol values in the table.
     * @details provide VICE compatable symbols.
     * @return std::string containing the exported_symbols
     *
     */
    std::string Export() {
        std::string out;
        
        for (const auto& [sym, entry] : symbols_) {
            if (use_all_symbols ||entry.usage.size() > 0 ) {
                out += std::format("al C:{:04X} .{}\n", entry.value, sym);
            }
        }
        return out;
    }

    
    std::string XRef() const {
        std::string out;

        // 1. Collect references to symbols for sorting
        struct SymbolRef {
            const std::string* name;
            const SymbolEntry* entry;
        };

        std::vector<SymbolRef> sorted_symbols;
        sorted_symbols.reserve(symbols_.size());
        for (const auto& [sym, entry] : symbols_) {
            sorted_symbols.push_back({&sym, &entry});
        }

        // 2. Sort by value ascending (with name as tie-breaker for identical addresses)
        std::sort(sorted_symbols.begin(), sorted_symbols.end(), [](const SymbolRef& a, const SymbolRef& b) {
            if (a.entry->value != b.entry->value) {
                return a.entry->value < b.entry->value;
            }
            return *a.name < *b.name;
        });

        // Header
        out += std::format("{:<30} {:<7} {:<24} {:>4}     {}\n", 
                           "Symbol", "Value", "Defined", "Refs", "References");
        out += std::string(105, '-') + "\n";

        constexpr size_t REF_INDENT = 73;
        constexpr size_t MAX_WIDTH = 120;

        // 3. Output sorted entries
        for (const auto& item : sorted_symbols) {
            const std::string& sym = *item.name;
            const auto& entry = *item.entry;

            if (use_all_symbols || !entry.usage.empty()) {
                auto [def_file_id, def_line] = entry.defined;
                std::string def_fname = std::filesystem::path(src_mgr.GetFileName(def_file_id)).filename().string();
                std::string def_str = std::format("{}:{}", def_fname, def_line);

                std::string val_str = std::format("${:04X}", entry.value);
                std::string refs_count = std::format("{}", entry.usage.size());

                std::string line_prefix;
                if (sym.length() <= 30) {
                    line_prefix = std::format("{:<30} {:<7} {:<24} {:>4}     ", 
                                              sym, val_str, def_str, refs_count);
                } else {
                    out += std::format("{}\n", sym);
                    line_prefix = std::format("{:<30} {:<7} {:<24} {:>4}     ", 
                                              "", val_str, def_str, refs_count);
                }

                std::string current_line = line_prefix;
                std::string ref_padding(REF_INDENT, ' ');
                bool first_ref = true;

                for (const auto& [use_file_id, use_line] : entry.usage) {
                    std::string ref_item;
                    if (use_file_id == def_file_id) {
                        ref_item = std::format("{}", use_line);
                    } else {
                        std::string use_fname = std::filesystem::path(src_mgr.GetFileName(use_file_id)).filename().string();
                        ref_item = std::format("{}:{}", use_fname, use_line);
                    }

                    std::string sep = first_ref ? "" : ", ";

                    if (!first_ref && (current_line.length() + sep.length() + ref_item.length() > MAX_WIDTH)) {
                        out += current_line + "\n";
                        current_line = ref_padding + ref_item;
                    } else {
                        current_line += sep + ref_item;
                    }
                    first_ref = false;
                }

                out += current_line + "\n";
            }
        }
        return out;
    }

    /**
     * @brief Defines or updates a symbol value in the table.
     * @details Logs a diagnostic trace message if the symbol is present in the trace watchlist.
     * @param name The symbol identifier name.
     * @param val The 16-bit integer or memory address value to assign.
     * @return true if a new symbol was inserted or an existing symbol's value was updated;
     *         false if the symbol already exists with the exact same value.
     */
    bool Define(const std::string& name, uint16_t val, const std::pair<int, int>&location) {
        if (trace_syms_.contains(name)) {
            std::cout << "[" << tablename << " TRACE] " << name << " -> $"
                      << std::hex << std::uppercase << val << std::dec << std::nouppercase << "\n";
        }

        auto it = symbols_.find(name);

        if (it == symbols_.end()) {
            SymbolEntry entry(val, location);
            symbols_.emplace(name, entry);
            return true;
        }
        auto &entry = it->second;
        if (entry.value != val) {
            entry.value = val;
            return true;
        }
        return false;
    }

    /**
     * @brief Looks up a symbol's value by name using case-insensitive evaluation.
     * @param name The symbol name to locate.
     * @return std::optional<uint16_t> containing the value if found; otherwise, std::nullopt.
     */
    [[nodiscard]] std::optional<uint16_t> Lookup(std::string_view name, const std::pair<int, int>&location ) {
        if (auto it = symbols_.find(name); it != symbols_.end()) {
            auto &entry = it->second;
            entry.usage.push_back(location);
            return entry.value;
        }
        return std::nullopt;
    }

    /**
     * @brief Prints the entire symbol table contents formatted in 3 columns with 16-bit hex values.
     */
    void print() {
        auto count = 0;
        for (const auto& [sym, entry] : symbols_) {
            auto value = entry.value;
            std::cout <<
                std::setfill(' ') << std::setw(30) << sym <<
                " $" << std::setfill('0') << std::setw(4) << std::hex << value <<
                std::setw(0) << std::setfill(' ');
            if (++count == 3) {
                count = 0;
                std::cout << "\n";
            }
        }
        std::cout << "\n";
    }
};