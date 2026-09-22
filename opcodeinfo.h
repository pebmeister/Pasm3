#pragma once

/**
 * @file opcode_lookup.h
 * @brief Provides fast, O(1) lookup utilities for retrieving opcode information.
 */

#include <algorithm>
#include "opcodedict.h"

/**
 * @brief Retrieves opcode information using a direct integer token look-up.
 * 
 * Performance is O(1) leveraging the underlying dictionary data structure.
 * 
 * @param kind The token type or identifier integer representing the opcode.
 * @return const OpCodeInfo* Pointer to the matching opcode information struct, 
 *         or `nullptr` if the token kind is not found.
 */
inline const OpCodeInfo* FindOpCodeInfo(int kind) {
    auto it = opcodeDict.find(kind);
    return (it != opcodeDict.end()) ? &it->second : nullptr;
}

/**
 * @brief Retrieves opcode information using a string-based mnemonic query.
 * 
 * Case-insensitive. A reverse lookup hash map is lazily constructed on the 
 * very first invocation of this function to maintain O(1) lookup speeds.
 * 
 * @param mnemonic A string view representing the assembly mnemonic (e.g., "MOV", "add").
 * @return const OpCodeInfo* Pointer to the matching opcode information struct, 
 *         or `nullptr` if the mnemonic does not match any known opcode.
 */
inline const OpCodeInfo* FindOpCodeInfo(std::string_view mnemonic) {
    // 1. Build reverse index ONCE on first function call
    static const auto mnemonic_to_kind = []() {
        std::unordered_map<std::string, int> index;
        index.reserve(opcodeDict.size());

        for (const auto& [kind, info] : opcodeDict) {
            std::string lower_m(info.mnemonic);
            std::transform(lower_m.begin(), lower_m.end(), lower_m.begin(),
            [](unsigned char c) {
                return static_cast<char>(std::tolower(c));
            });

            index[lower_m] = kind;
        }
        return index;
    }
    ();

    // 2. Lowercase the search query
    std::string lower_key(mnemonic);
    std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
    [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });

    // 3. O(1) hash lookup into index, then direct lookup in opcodeDict
    auto it = mnemonic_to_kind.find(lower_key);
    if (it != mnemonic_to_kind.end()) {
        return FindOpCodeInfo(it->second);
    }

    return nullptr;
}
