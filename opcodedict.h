/**
 * @file opcodeinfo.h
 * @brief Defines the OpCodeInfo structure for storing 6502 instruction specifications.
 * @author Paul Baxter
 */

#pragma once
#include <cstdint>
#include <map>
#include <string>
#include <string_view>

#include "ruletype.h"
#include "tokenkind.h"
#include "opcodes.h"

/**
 * @struct OpCodeInfo
 * @brief Holds metadata for a 6502 family CPU instruction, including addressing modes, opcodes, and cycle counts.
 */
struct OpCodeInfo {
    std::string_view mnemonic;                                    /**< Instruction mnemonic string (e.g., "LDA", "STA"). */
    std::map<RULE_TYPE, std::pair<uint8_t, int>> mode_to_opcode; /**< Map from addressing mode (RULE_TYPE) to a pair containing {opcode_byte, cycle_count}. */
    bool is_65c02 = false;                                       /**< Flag indicating whether the instruction is specific to the 65C02 architecture. */
    bool is_illegal = false;                                     /**< Flag indicating whether the instruction is an undocumented/illegal 6502 opcode. */
    std::string_view description;                                /**< Brief narrative description of the instruction's operation. */

    /**
     * @brief Constructs an OpCodeInfo instance with specified instruction parameters.
     * 
     * @param mnemonic String view representing the instruction mnemonic.
     * @param mode_to_opcode Map linking addressing modes to their opcode byte and cycle count.
     * @param is_65c02 Set to true if exclusive to the 65C02 processor variant.
     * @param is_illegal Set to true if an undocumented/illegal 6502 opcode.
     * @param description Brief textual description of the instruction.
     */
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

/**
 * @var opcodeDict
 * @brief Global dictionary mapping token identifiers to their opcode information.
 */
extern std::map<int, OpCodeInfo> opcodeDict;
