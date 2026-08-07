#pragma once
#include <map>
#include <string>
#include <string_view>

enum class TokenKind {
    Eof=-1,
    Invalid=-2,
    Newline=1,
    Ws,
    MacroArg,
    Semicolon,
    Opcode,
    Label,
    Identifier,
    Number,
    PcSymbol,
    Hash,
    Comma,
    LParen,
    RParen,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Ampersand,
    Pipe,
    Caret,
    Shl,
    Shr,
    Equal,
    LowByte,
    HighByte,
    Tilde,
    Bang,
    Directive
};

extern std::map<TokenKind, std::string_view> tokmap;
#ifdef GEN_TOKMAP

std::map<TokenKind, std::string_view> tokmap = {
    { TokenKind::Eof,"Eof"},
    { TokenKind::Newline,"Newline"},
    { TokenKind::Ws,"Ws"},
    { TokenKind::Semicolon,"Semicolon"},
    { TokenKind::Opcode,"Opcode"},
    { TokenKind::Label,"Label"},
    { TokenKind::Identifier,"Identifier"},
    { TokenKind::Number,"Number"},
    { TokenKind::PcSymbol,"PcSymbol"},
    { TokenKind::Hash,"Hash"},
    { TokenKind::Comma,"Comma"},
    { TokenKind::LParen,"LParen"},
    { TokenKind::RParen,"RParen"},
    { TokenKind::Plus,"Plus"},
    { TokenKind::Minus,"Minus"},
    { TokenKind::Star,"Star"},
    { TokenKind::Slash,"Slash"},
    { TokenKind::Percent,"Percent"},
    { TokenKind::Ampersand,"Ampersand"},
    { TokenKind::Pipe,"Pipe"},
    { TokenKind::Caret,"Caret"},
    { TokenKind::Shl,"Shl"},
    { TokenKind::Shr,"Shr"},
    { TokenKind::Equal,"Equal"},
    { TokenKind::LowByte,"LowByte"},
    { TokenKind::HighByte,"HighByte"},
    { TokenKind::Tilde,"Tilde"},
    { TokenKind::Bang,"Bang"},
    { TokenKind::Directive,"Directive"}
};

#endif
