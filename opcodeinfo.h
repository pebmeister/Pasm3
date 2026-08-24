#pragma once
#include <algorithm>

// Direct O(1) lookup by TokenKind
inline const OpCodeInfo* FindOpCodeInfo(int kind) {
    auto it = opcodeDict.find(kind);
    return (it != opcodeDict.end()) ? &it->second : nullptr;
}

// Fast O(1) lookup by string mnemonic using a lazily-built index
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
