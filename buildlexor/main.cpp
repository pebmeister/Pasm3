/**
 * @file main.cpp
 * @author Paul Baxter
 * @brief Driver application for generating the 6502/65C02 assembler tokenizer class.
 * @details Utilizes the RegexCompiler engine to build an NFA/DFA state machine based on
 *          defined regular expression rules for assembly tokens (labels, opcodes, 
 *          directives, numbers, and operators). Serializes the compiled state machine 
 *          into a standalone C++ header file (`PasmTokenizer.hpp`).
 */

#include <iostream>
#include <fstream>
#include "RegexEngine.h" // Header containing your NFABuilder, DFAConverter, and RegexCompiler
#include "tokenkind.h"

using enum TokenKind;

/**
 * @brief Application entry point.
 * @details Configures the regular expression rules for the assembly lexer, compiles 
 *          the state machine, and generates the resulting C++ class file.
 * @return Returns 0 upon successful code generation.
 */
int main() {
    RegexCompiler compiler;

    /**
     * @section Lexer Rules Configuration
     * Defines regular expression patterns mapped to TokenKind enumeration IDs.
     * Note: Case-insensitive flags are enabled (`true`) where appropriate for 
     *       opcodes, hex values, identifiers, and directives.
     */
    compiler.addRules({
        // --- Structural & Whitespace Tokens ---
        { "[\\r]?[\\n]",                     static_cast<int>(Newline) },
        { "[ \\t]*",                         static_cast<int>(Ws) },
        { "[;]",                             static_cast<int>(Semicolon) },
        { "[\\\\][1-9]+",                    static_cast<int>(MacroArg) },

        // --- Identifiers, Labels, and Directives ---
        { "[@]?[a-z_][a-z0-9_]*[:]?",        static_cast<int>(Identifier), true },
        { "[\\.][a-z_][a-z0-9_]*",           static_cast<int>(Directive), true },

        // --- Literals (Decimal, Hex, Binary, Character, String) ---
        { "[0-9]+",                          static_cast<int>(Number) },
        { "[$][0-9|a-f]+",                   static_cast<int>(Number), true },
        { "[%][0-1]+",                       static_cast<int>(Number) },
        { "'.'",                             static_cast<int>(Number) },
        { "\"[^\r\n\"]*\"",                  static_cast<int>(StringLiteral), true },

        // --- Assignment & Directives ---
        { "[=]",                             static_cast<int>(Equal) },
        { "\\.equ",                          static_cast<int>(Equal), true },

        // --- Operators & Delimiters ---
        { "[\\*]",                           static_cast<int>(Star) },
        { "[,]",                             static_cast<int>(Comma) },
        { "[%]",                             static_cast<int>(Percent) },
        { "[&]",                             static_cast<int>(Ampersand) },
        { "[&]{2}",                          static_cast<int>(AmpersandAmpersand) },
        { "[\\(]",                           static_cast<int>(LParen) },
        { "[\\)]",                           static_cast<int>(RParen) },
        { "[\\+]",                           static_cast<int>(Plus) },
        { "[\\-]",                           static_cast<int>(Minus) },
        { "[\\#]",                           static_cast<int>(Hash) },
        { "[\\|]",                           static_cast<int>(Pipe) },
        { "[\\|]{2}",                        static_cast<int>(PipePipe) },
        { "[\\^]",                           static_cast<int>(Caret) },
        { "[\\<]",                           static_cast<int>(LowByte) },
        { "[\\>]",                           static_cast<int>(HighByte) },
        { "(\\<){2}",                        static_cast<int>(Shl) },
        { "(\\>){2}",                        static_cast<int>(Shr) },
        { "[=]{2}",                          static_cast<int>(EqualEqual) },
        { "[!][=]",                          static_cast<int>(NotEqual) },
        { "[\\<][=]",                        static_cast<int>(LessEqual) },
        { "[\\>][=]",                        static_cast<int>(GreaterEqual) },
        { "[~]",                             static_cast<int>(Tilde) },
        { "[!]",                             static_cast<int>(Bang) },

        // --- 6502 / 65C02 / Illegal Opcodes (Case-Insensitive) ---
        { "ORA|AND|EOR|ADC|SBC",             static_cast<int>(Opcode), true },
        { "CMP|CPX|CPY|DEC|DEX",             static_cast<int>(Opcode), true },
        { "DEY|INC|INX|INY|ASL",             static_cast<int>(Opcode), true },
        { "ROL|LSR|ROR|LDA|STA",             static_cast<int>(Opcode), true },
        { "LDX|STX|LDY|STY|STZ",             static_cast<int>(Opcode), true },
        { "TAX|TXA|TAY|TYA|TSX",             static_cast<int>(Opcode), true },
        { "TXS|PLA|PHA|PLP|PHP",             static_cast<int>(Opcode), true },
        { "PHX|PHY|PLX|PLY|BRA",             static_cast<int>(Opcode), true },
        { "BPL|BMI|BVC|BVS|BCC",             static_cast<int>(Opcode), true },
        { "BCS|BNE|BEQ|STP|WAI",             static_cast<int>(Opcode), true },
        { "BRK|RTI|JSR|RTS|JMP",             static_cast<int>(Opcode), true },
        { "BIT|CLC|SEC|CLD|SED",             static_cast<int>(Opcode), true },
        { "CLI|SEI|CLV|NOP|SLO",             static_cast<int>(Opcode), true },
        { "RLA|SRE|RRA|SAX|LAX",             static_cast<int>(Opcode), true },
        { "DCP|ISC|ANC|ANC2|ARR",            static_cast<int>(Opcode), true },
        { "XAA|AXS|USBC|AHX|SHY",            static_cast<int>(Opcode), true },
        { "SHX|TAS|LAS|TRB|TSB",             static_cast<int>(Opcode), true },
        { "RMB[0-7]|SMB[0-7]",               static_cast<int>(Opcode), true },
        { "BBR[0-7]|BBS[0-7]",               static_cast<int>(Opcode), true },
    });

    std::string classname = "PasmTokenizer";
    std::string outfile = "../PasmTokenizer.hpp";

    /**
     * @section C++ Class Code Generation & Serialization
     * Generates C++ source code containing the compiled state transition tables
     * and writes the result to the destination header file.
     */
    std::string generated_code = compiler.generateCppClass(classname);

    std::ofstream out(outfile);
    out << generated_code;
    out.close();

    return 0;
}
