/**
 * @file ruletype.h
 * @brief Defines CPU instruction addressing modes and string mapping utilities for 6502/65C02 assembly.
 * @author Paul Baxter
 */

#pragma once
#include <map>
#include <string_view>

/**
 * @enum RULE_TYPE
 * @brief Identifies the operand addressing mode for an instruction.
 */
enum RULE_TYPE {
    Op_Implied,          /**< Implied mode; operand is inherent to the opcode (e.g., RTS, NOP). */
    Op_Immediate,        /**< Immediate mode; 8-bit literal constant (e.g., LDA #$01). */
    Op_Absolute,         /**< Absolute mode; 16-bit memory address (e.g., STA $1234). */
    Op_ZeroPage,         /**< Zero-page mode; 8-bit address in $0000–$00FF (e.g., STA $80). */
    Op_AbsoluteX,        /**< Absolute indexed with X register (e.g., LDA $1234,X). */
    Op_ZeroPageX,        /**< Zero-page indexed with X register (e.g., LDA $80,X). */
    Op_AbsoluteY,        /**< Absolute indexed with Y register (e.g., LDA $1234,Y). */
    Op_ZeroPageY,        /**< Zero-page indexed with Y register (e.g., LDX $80,Y). */
    Op_Indirect,         /**< Absolute indirect mode (e.g., JMP ($1234)). */
    Op_IndirectX,        /**< Zero-page indexed indirect with X (e.g., LDA ($80,X)). */
    Op_IndirectY,        /**< Zero-page indirect indexed with Y (e.g., LDA ($80),Y). */
    Op_Accumulator,      /**< Accumulator mode; targets register A explicitly (e.g., ASL A). */
    Op_Relative,         /**< Relative mode; signed 8-bit offset for branches (e.g., BNE label). */
    Op_ZeroPageRelative  /**< Zero-page bit branch relative mode for 65C02 (e.g., BBR0 $80, label). */
};

/**
 * @var rulemap
 * @brief Maps addressing mode RULE_TYPE enumerators to their textual string representations.
 */
extern std::map<RULE_TYPE, std::string_view> rulemap;

#ifdef GEN_RULEMAP
std::map<RULE_TYPE, std::string_view> rulemap = {
    { Op_Implied, "Op_Implied" },
    { Op_Immediate, "Op_Immediate" },
    { Op_Absolute, "Op_Absolute" },
    { Op_ZeroPage, "Op_ZeroPage" },
    { Op_AbsoluteX, "Op_AbsoluteX" },
    { Op_ZeroPageX, "Op_ZeroPageX" },
    { Op_AbsoluteY, "Op_AbsoluteY" },
    { Op_ZeroPageY, "Op_ZeroPageY" },
    { Op_Indirect, "Op_Indirect" },
    { Op_IndirectX, "Op_IndirectX" },
    { Op_IndirectY, "Op_IndirectY" },
    { Op_Accumulator, "Op_Accumulator" },
    { Op_Relative, "Op_Relative" },
    { Op_ZeroPageRelative, "Op_ZeroPageRelative" }
};
#endif
