#pragma once
#include <cctype>
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <algorithm> // Required for std::ranges::contains
#include <unordered_set>

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

	std::unordered_set<std::string> trace_syms_;
	

public:
	void Trace(const std::string& name) {
        trace_syms_.insert(name);
    }

    void Untrace(const std::string& name) {
        trace_syms_.erase(name);
    }
	
    bool Define(const std::string& name, uint16_t val) {		

		if (trace_syms_.contains(name)) { 
            std::cout << "[SYM TRACE] " << name << " -> $" 
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

    [[nodiscard]] std::optional<uint16_t> Lookup(std::string_view name) const {
        if (auto it = symbols_.find(name); it != symbols_.end()) {
            return it->second;
        }
        return std::nullopt;
    }
	
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
