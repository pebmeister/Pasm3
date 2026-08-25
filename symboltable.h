#pragma once
#include <cctype>
#include <cstdint>
#include <iostream>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>

class SymbolTable {
private:
    struct CaseInsensitiveHash {
        using is_transparent = void;

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

    struct CaseInsensitiveEqual {
        using is_transparent = void;

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

    std::unordered_map<
        std::string,
        uint16_t,
        CaseInsensitiveHash,
        CaseInsensitiveEqual
    > symbols_;

public:
    bool Define(const std::string& name, uint16_t val) {
        auto it = symbols_.find(name);
        if (it == symbols_.end()) {
            symbols_.emplace(name, val);
			std::cout << "define " << name << " $" << std::hex << val << std::dec << "\n";
            return true;
        }
        if (it->second != val) {
            it->second = val;
			std::cout << "change " << name << " $" << std::hex << val << std::dec << "\n";
            return true;
        }
        return false;
    }

    [[nodiscard]] std::optional<uint16_t> Lookup(std::string_view name) const {
        if (auto it = symbols_.find(name); it != symbols_.end()) {
            return it->second;
        }
        return std::nullopt;
    }
};
