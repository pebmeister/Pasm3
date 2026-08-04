#include <iostream>
#include <fstream>
#include "RegexEngine.h" // Header containing your NFABuilder, DFAConverter, and RegexCompiler

// 1. Define distinct Token IDs for your grammar
enum class TokenKind {
    Eof=-1,
    Newline=1, 
    Semicolon,
    Opcode, Label, Identifier, Number, PcSymbol,
    Hash, Comma, LParen, RParen,
    Plus, Minus, Star, Slash, Percent,
    Ampersand, Pipe, Caret, Shl, Shr, Equal,
    LowByte, HighByte, Tilde, Bang, Directive,
};
using enum TokenKind;

int main() {
    RegexCompiler compiler;

    compiler.addRules({
		{ "\\n", static_cast<int>(Newline)},
		{ ";", static_cast<int>(Semicolon)},
		{ "^[a-zA-Z_][a-zA-Z0-9_]*:?", static_cast<int>(Label)},
		{ "[a-zA-Z_][a-zA-Z0-9_]*", static_cast<int>(Identifier)},
		
        { "ORA|AND|EOR|ADC|SBC", static_cast<int>(Opcode), true},
        { "CMP|CPX|CPY|DEC|DEX", static_cast<int>(Opcode), true},
        { "DEY|INC|INX|INY|ASL", static_cast<int>(Opcode), true},
        { "ROL|LSR|ROR|LDA|STA", static_cast<int>(Opcode), true},
        { "LDX|STX|LDY|STY|STZ", static_cast<int>(Opcode), true},
        { "TAX|TXA|TAY|TYA|TSX", static_cast<int>(Opcode), true},
        { "TXS|PLA|PHA|PLP|PHP", static_cast<int>(Opcode), true},
        { "PHX|PHY|PLX|PLY|BRA", static_cast<int>(Opcode), true},
        { "BPL|BMI|BVC|BVS|BCC", static_cast<int>(Opcode), true},
        { "BCS|BNE|BEQ|STP|WAI", static_cast<int>(Opcode), true},
        { "BRK|RTI|JSR|RTS|JMP", static_cast<int>(Opcode), true},
		{ "BIT|CLC|SEC|CLD|SED", static_cast<int>(Opcode), true},
		{ "CLI|SEI|CLV|NOP|SLO", static_cast<int>(Opcode), true},
		{ "RLA|SRE|RRA|SAX|LAX", static_cast<int>(Opcode), true},
		{ "DCP|ISC|ANC|ANC2|ARR",static_cast<int>(Opcode), true},
		{ "XAA|AXS|USBC|AHX|SHY",static_cast<int>(Opcode), true},
		{ "SHX|TAS|LAS|TRB|TSB", static_cast<int>(Opcode), true},
        { "RMB[0-7]|SMB[0-7]",   static_cast<int>(Opcode), true},
        { "BBR[0-7]|BBS[0-7]",   static_cast<int>(Opcode), true},
    });


    // 2. Generate the C++ code for the compiled DFA tokenizer
    std::string generated_code = compiler.generateCppClass("PasmTokenizer");

    // 3. Save the generated class to a standalone header file
    std::ofstream out("PasmTokenizer.hpp");
    out << generated_code;
    out.close();

    std::cout << "Successfully generated 'PasmTokenizer.hpp'!\n";
    return 0;
}
