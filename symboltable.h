/**
 * @file symboltable.h
 * @brief Case-insensitive symbol table with tracing support for assembler addresses and constants.
 * @author Paul Baxter
 */

#pragma once

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

/**
 * @class SymbolTable
 * @brief Case-insensitive lookup table for mapping identifiers to 16-bit address or integer values.
 *
 * Supports transparent string view lookup, case-insensitive FNV-1a hashing, and active symbol
 * tracing/logging upon definition or modification.
 */
class SymbolTable {
private:
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
        uint16_t,
        CaseInsensitiveHash,
        CaseInsensitiveEqual
    > symbols_;

    std::unordered_set<std::string> trace_syms_; /**< Set of symbol identifiers actively configured for tracing. */

public:
    /**
     * @brief Constructs a SymbolTable instance with a specific table name.
     * @param name Descriptive label used in diagnostic trace output.
     */
    explicit SymbolTable(std::string name) : tablename(std::move(name)) {
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
     * @brief Defines or updates a symbol value in the table.
     * @details Logs a diagnostic trace message if the symbol is present in the trace watchlist.
     * @param name The symbol identifier name.
     * @param val The 16-bit integer or memory address value to assign.
     * @return true if a new symbol was inserted or an existing symbol's value was updated;
     *         false if the symbol already exists with the exact same value.
     */
    bool Define(const std::string& name, uint16_t val) {
        if (trace_syms_.contains(name)) {
            std::cout << "[" << tablename << " TRACE] " << name << " -> $"
                      << std::hex << std::uppercase << val << std::dec << std::nouppercase << "\n";
        }

        auto it = symbols_.find(name);

        if (it == symbols_.end()) {
            symbols_.emplace(name, val);
            return true;
        }
        if (it->second != val) {
            it->second = val;
            return true;
        }
        return false;
    }

    /**
     * @brief Looks up a symbol's value by name using case-insensitive evaluation.
     * @param name The symbol name to locate.
     * @return std::optional<uint16_t> containing the value if found; otherwise, std::nullopt.
     */
    [[nodiscard]] std::optional<uint16_t> Lookup(std::string_view name) const {
        if (auto it = symbols_.find(name); it != symbols_.end()) {
            return it->second;
        }
        return std::nullopt;
    }

    /**
     * @brief Prints the entire symbol table contents formatted in 3 columns with 16-bit hex values.
     */
    void print() {
        auto count = 0;
        for (const auto& [sym, value] : symbols_) {
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