/**
 * @file opcodes.h
 * @brief Enumeration of 6502, 65C02, and undocumented/illegal CPU instruction mnemonics.
 * @author Paul Baxter
 */

#pragma once

/**
 * @enum Opcode
 * @brief Represents CPU instruction opcodes supported by the assembler.
 * 
 * Includes standard MOS 6502 instructions, WDC 65C02 extensions (such as bit manipulation 
 * and zero-page branch instructions), and common undocumented/illegal 6502 opcodes.
 */
enum Opcode {
    // Standard 6502 ALU and Memory Operations
    ORA, AND, EOR, ADC, SBC,
    CMP, CPX, CPY, DEC, DEX,
    DEY, INC, INX, INY, ASL,
    ROL, LSR, ROR, LDA, STA,
    LDX, STX, LDY, STY,

    // 65C02 Bit Manipulation Directives
    RMB0, RMB1, RMB2, RMB3, RMB4, RMB5, RMB6, RMB7,
    SMB0, SMB1, SMB2, SMB3, SMB4, SMB5, SMB6, SMB7,

    // Register Transfers & Stack Operations
    STZ, TAX, TXA, TAY, TYA,
    TSX, TXS, PLA, PHA, PLP,
    PHP, PHX, PHY, PLX, PLY,

    // Control Flow & Branching
    BRA, BPL, BMI, BVC, BVS,
    BCC, BCS, BNE, BEQ,

    // 65C02 Bit Branching Directives
    BBR0, BBR1, BBR2, BBR3, BBR4, BBR5, BBR6, BBR7,
    BBS0, BBS1, BBS2, BBS3, BBS4, BBS5, BBS6, BBS7,

    // Control & Subroutine Instructions
    STP, WAI, BRK, RTI, JSR, 
    RTS, JMP, BIT,

    // Processor Status Flag Operations
    CLC, SEC, CLD, SED, CLI,
    SEI, CLV, NOP,

    // Undocumented / Illegal 6502 Opcodes
    SLO, RLA, SRE, RRA, SAX,
    LAX, DCP, ISC, ANC, ANC2,
    ALR, ARR, XAA, AXS, USBC,
    AHX, SHY, SHX, TAS, LAS,

    // 65C02 Bit Test & Reset/Set
    TRB, TSB
};