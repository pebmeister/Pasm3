/**
 * @file tokenkind.h
 * @brief Defines lexical token types and string mapping utilities for the assembler tokenizer.
 * @author Paul Baxter
 */

#pragma once

#include <map>
#include <string>
#include <string_view>

/**
 * @enum TokenKind
 * @brief Identifies the category and lexical type of a token produced by the tokenizer.
 */
enum class TokenKind {
    Eof = -1,            /**< End-of-file indicator token. */
    Invalid = -2,        /**< Unrecognized or illegal character token. */
    Newline = 1,         /**< Newline / line break character sequence. */
    Ws,                  /**< Whitespace sequence (spaces, tabs). */
    MacroArg,            /**< Macro argument substitution reference (e.g., \1). */
    Semicolon,           /**< Semicolon comment delimiter (;). */
    Opcode,              /**< CPU instruction mnemonic (e.g., LDA, STA, NOP). */
    Label,               /**< Code label declaration (ending with :). */
    Identifier,          /**< Symbol, constant name, or variable identifier. */
    Number,              /**< Numeric constant literal (decimal, hex, binary, or character). */
    StringLiteral,       /**< Quoted text string literal. */
    Hash,                /**< Immediate addressing mode prefix (#). */
    Comma,               /**< Operand or parameter separator (,). */
    LParen,              /**< Opening parenthesis ((). */
    RParen,              /**< Closing parenthesis ()). */
    Plus,                /**< Addition operator (+). */
    Minus,               /**< Subtraction operator (-). */
    Star,                /**< Multiplication operator (*) or origin counter reference. */
    Slash,               /**< Division operator (/). */
    Percent,             /**< Modulo operator (%). */
    Ampersand,           /**< Bitwise AND operator (&). */
    AmpersandAmpersand,  /**< Logical AND operator (&&). */
    Pipe,                /**< Bitwise OR operator (|). */
    PipePipe,            /**< Logical OR operator (||). */
    Caret,               /**< Bitwise XOR operator (^). */
    Shl,                 /**< Bitwise shift left operator (<<). */
    Shr,                 /**< Bitwise shift right operator (>>). */
    Equal,               /**< Assignment operator (=). */
    EqualEqual,          /**< Relational equality operator (==). */
    NotEqual,            /**< Relational inequality operator (!=). */
    Less,                /**< Relational less-than operator (<). */
    LessEqual,           /**< Relational less-than or equal operator (<=). */
    Greater,             /**< Relational greater-than operator (>). */
    GreaterEqual,        /**< Relational greater-than or equal operator (>=). */
    LowByte,             /**< Unary low-byte operator (< prefix). */
    HighByte,            /**< Unary high-byte operator (> prefix). */
    Tilde,               /**< Bitwise NOT operator (~). */
    Bang,                /**< Logical NOT operator (!). */
    Directive            /**< Assembler directive keyword (e.g., .org, .byte). */
};

/**
 * @var tokmap
 * @brief Maps TokenKind enumerators to their textual string representations.
 */
extern std::map<TokenKind, std::string_view> tokmap;

#ifdef GEN_TOKMAP

std::map<TokenKind, std::string_view> tokmap = {
    { TokenKind::Eof, "Eof" },
    { TokenKind::Newline, "Newline" },
    { TokenKind::Ws, "Ws" },
    { TokenKind::Semicolon, "Semicolon" },
    { TokenKind::Opcode, "Opcode" },
    { TokenKind::Label, "Label" },
    { TokenKind::Identifier, "Identifier" },
    { TokenKind::Number, "Number" },
    { TokenKind::StringLiteral, "StringLiteral" },
    { TokenKind::Hash, "Hash" },
    { TokenKind::Comma, "Comma" },
    { TokenKind::LParen, "LParen" },
    { TokenKind::RParen, "RParen" },
    { TokenKind::Plus, "Plus" },
    { TokenKind::Minus, "Minus" },
    { TokenKind::Star, "Star" },
    { TokenKind::Slash, "Slash" },
    { TokenKind::Percent, "Percent" },
    { TokenKind::Ampersand, "Ampersand" },
    { TokenKind::AmpersandAmpersand, "AmpersandAmpersand" },
    { TokenKind::Pipe, "Pipe" },
    { TokenKind::PipePipe, "PipePipe" },
    { TokenKind::Caret, "Caret" },
    { TokenKind::Shl, "Shl" },
    { TokenKind::Shr, "Shr" },
    { TokenKind::Equal, "Equal" },
    { TokenKind::EqualEqual, "EqualEqual" },
    { TokenKind::NotEqual, "NotEqual" },
    { TokenKind::Less, "Less" },
    { TokenKind::LessEqual, "LessEqual" },
    { TokenKind::Greater, "Greater" },
    { TokenKind::GreaterEqual, "GreaterEqual" },
    { TokenKind::LowByte, "LowByte" },
    { TokenKind::HighByte, "HighByte" },
    { TokenKind::Tilde, "Tilde" },
    { TokenKind::Bang, "Bang" },
    { TokenKind::Directive, "Directive" }
};

#endif
