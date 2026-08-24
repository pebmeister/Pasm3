#pragma once
#include <cstdint>
#include <optional>

class SymbolTable {
private:
	// Case-insensitive hash function
	struct CaseInsensitiveHash {
		using is_transparent = void;

		std::size_t operator()(std::string_view sv) const {
			std::size_t hash = static_cast<std::size_t>(14695981039346656037ULL); // FNV-1a offset basis
			for (char c : sv) {
				auto uc = static_cast<unsigned char>(c);
				hash ^= static_cast<std::size_t>(std::tolower(uc));
				hash *= 1099511628211ULL; // FNV-1a prime
			}
			return hash;
		}
	};

	// Case-insensitive equality predicate
	struct CaseInsensitiveEqual {
		using is_transparent = void;

		bool operator()(std::string_view lhs, std::string_view rhs) const {
			return std::equal(
					   lhs.begin(), lhs.end(),
					   rhs.begin(), rhs.end(),
			[](unsigned char a, unsigned char b) {
				return std::tolower(a) == std::tolower(b);
			}
				   );
		}
	};


    // Map with custom Key, Value, Hash, and KeyEqual types
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
            symbols_[name] = val;
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
};