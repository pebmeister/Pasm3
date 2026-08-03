// written by Paul Baxter
#pragma once
#include <cstdint>
#include <map>
#include <string>
#include <string_view>

#include "ruletype.h"
#include "opcodes.h"

struct OpCodeInfo {
    std::string_view mnemonic;
    std::map<RULE_TYPE, std::pair<uint8_t, int>> mode_to_opcode;
    bool is_65c02 = false;
    bool is_illegal = false;
    std::string_view description;

    // Constructor for convenience
    OpCodeInfo(
        std::string_view mnemonic,
        std::map<RULE_TYPE, std::pair<uint8_t, int>> mode_to_opcode,
        bool is_65c02 = false,
        bool is_illegal = false,
        std::string_view description = ""
    )
        : mnemonic(std::move(mnemonic)),
        mode_to_opcode(std::move(mode_to_opcode)),
        is_65c02(is_65c02),
        is_illegal(is_illegal),
        description(std::move(description))
    {
    }
};

extern std::map<TokenKind, OpCodeInfo> opcodeDict;
