#include <iostream>
#include <fstream>
#include "RegexEngine.h" // Header containing your NFABuilder, DFAConverter, and RegexCompiler

#include "tokenkind.h"

using enum TokenKind;

int main() {
    RegexCompiler compiler;

compiler.addRules({
    { "[\\r]?[\\n]", static_cast<int>(Newline)},
    { "[ \\t]*", static_cast<int>(Ws)},
    { "[;]", static_cast<int>(Semicolon)},
    { "[\\\\][1-9]+", static_cast<int>(MacroArg)},
    { "[@]?[a-z_][a-z0-9_]*[:]?", static_cast<int>(Identifier), true},
    { "[\\.][a-z_][a-z0-9_]*", static_cast<int>(Directive), true},
    { "[0-9]+", static_cast<int>(Number)},
    { "[$][0-9|a-f]+", static_cast<int>(Number), true},
    { "[%][0-1]+", static_cast<int>(Number)},
    { "'.'", static_cast<int>(Number)},
	{ "\"[^\r\n\"]*\"", static_cast<int>(StringLiteral), true },
    { "[=]", static_cast<int>(Equal)},
    { "[\\*]", static_cast<int>(Star)},
    { "[,]", static_cast<int>(Comma)},
    { "[%]", static_cast<int>(Percent)},
    { "[&]", static_cast<int>(Ampersand)},
    { "[\\(]", static_cast<int>(LParen)},
    { "[\\)]", static_cast<int>(RParen)},
    { "[\\+]", static_cast<int>(Plus)},
    { "[\\-]", static_cast<int>(Minus)},
    { "[\\#]", static_cast<int>(Hash)},
    { "[\\|]", static_cast<int>(Pipe)},
    { "[\\^]", static_cast<int>(Caret)},
    { "[\\<]", static_cast<int>(LowByte)},
    { "[\\>]", static_cast<int>(HighByte)},
    { "(\\<){2}", static_cast<int>(Shl)},
    { "(\\>){2}", static_cast<int>(Shr)},
    { "[~]", static_cast<int>(Tilde)},
    { "[!]", static_cast<int>(Bang)},
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
    { "DCP|ISC|ANC|ANC2|ARR", static_cast<int>(Opcode), true},
    { "XAA|AXS|USBC|AHX|SHY", static_cast<int>(Opcode), true},
    { "SHX|TAS|LAS|TRB|TSB", static_cast<int>(Opcode), true},
    { "RMB[0-7]|SMB[0-7]",   static_cast<int>(Opcode), true},
    { "BBR[0-7]|BBS[0-7]",   static_cast<int>(Opcode), true},
});


	std::string classname = "PasmTokenizer";
	std::string outfile = "../PasmTokenizer.hpp";

    // 2. Generate the C++ code for the compiled DFA tokenizer
    std::string generated_code = compiler.generateCppClass(classname);

    // 3. Save the generated class to a standalone header file
    std::ofstream out(outfile);
    out << generated_code;
    out.close();

    std::cout << "Successfully generated '" << outfile << "'!\n";
    return 0;
}
