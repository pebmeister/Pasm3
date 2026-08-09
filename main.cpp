// Written by Paul Baxter

#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <map>
#include <unordered_map>
#include <cstdint>
#include <cctype>
#include <optional>
#include <algorithm>
#include <iomanip>
#include <sstream>
#include <utility>
#include <format>
#include <fstream>
#include <sstream>
#include <exception>
#include <chrono>

#include "ruletype.h"

#define GEN_TOKMAP
#include "tokenkind.h"

#include "opcodedict.h"
#include "PasmTokenizer.hpp"

struct MacroDef {
    std::string name;
    std::vector<PasmTokenizer::Token> body_tokens;
};

// Add this as a private member in your Parser class
std::unordered_map<std::string, MacroDef> macros_;

// ============================================================================
// 1. Core Enums & Data Structures
// ============================================================================

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

// ============================================================================
// 2. AST Expression Subsystem
// ============================================================================

enum class Associativity { Left, Right };

struct OpPrecedence {
    int prec;
    Associativity assoc;
};

struct ExprNode {
    virtual ~ExprNode() = default;
};

struct NumberExpr : ExprNode {
    int64_t value;
    explicit NumberExpr(int64_t val) : value(val) {}
};

struct SymbolExpr : ExprNode {
    std::string name;
    explicit SymbolExpr(std::string n) : name(std::move(n)) {}
};

struct UnaryExpr : ExprNode {
    int op;
    std::unique_ptr<ExprNode> operand;
    UnaryExpr(int op, std::unique_ptr<ExprNode> rhs)
        : op(op), operand(std::move(rhs)) {}
};

struct BinaryExpr : ExprNode {
    int op;
    std::unique_ptr<ExprNode> lhs;
    std::unique_ptr<ExprNode> rhs;
    BinaryExpr(int op, std::unique_ptr<ExprNode> l, std::unique_ptr<ExprNode> r)
        : op(op), lhs(std::move(l)), rhs(std::move(r)) {}
};

class ExprResult {
    std::unique_ptr<ExprNode> node_{nullptr};
    bool invalid_{false};

public:
    ExprResult() = default;
    ExprResult(std::unique_ptr<ExprNode> node) : node_(std::move(node)) {}

    static ExprResult Error() {
        ExprResult res;
        res.invalid_ = true;
        return res;
    }

    [[nodiscard]] bool isInvalid() const {
        return invalid_;
    }
    [[nodiscard]] bool isUsable() const {
        return !invalid_ && node_ != nullptr;
    }
    const ExprNode* get() const {
        return node_.get();
    }
    std::unique_ptr<ExprNode> release() {
        return std::move(node_);
    }
};

size_t GetInstructionSize(RULE_TYPE mode) {
    switch (mode) {
        case RULE_TYPE::Op_Implied:
        case RULE_TYPE::Op_Accumulator:
            return 1;

        case RULE_TYPE::Op_Immediate:
        case RULE_TYPE::Op_ZeroPage:
        case RULE_TYPE::Op_ZeroPageX:
        case RULE_TYPE::Op_ZeroPageY:
        case RULE_TYPE::Op_IndirectX:
        case RULE_TYPE::Op_IndirectY:
        case RULE_TYPE::Op_Relative:
            return 2;

        case RULE_TYPE::Op_Absolute:
        case RULE_TYPE::Op_AbsoluteX:
        case RULE_TYPE::Op_AbsoluteY:
        case RULE_TYPE::Op_Indirect:
            return 3;

        default:
            return 1;
    }
}

// Case-insensitive hash function
struct CaseInsensitiveHash {
    using is_transparent = void;

    std::size_t operator()(std::string_view sv) const {
        std::size_t hash = 14695981039346656037ULL; // FNV-1a offset basis
        for (char c : sv) {
            auto uc = static_cast<unsigned char>(c);
            hash ^= static_cast<std::size_t>(std::tolower(uc));
            hash *= 1099511628211ULL; // FNV-1a prime
        }
        return hash;
    }
};

// Case-insensitive equality predicate
struct CaseInsensitiveEqual {
    using is_transparent = void;

    bool operator()(std::string_view lhs, std::string_view rhs) const {
        return std::equal(
            lhs.begin(), lhs.end(),
            rhs.begin(), rhs.end(),
            [](unsigned char a, unsigned char b) {
                return std::tolower(a) == std::tolower(b);
            }
        );
    }
};

class SymbolTable {
    // Map with custom Key, Value, Hash, and KeyEqual types
    std::unordered_map<
        std::string,
        uint16_t,
        CaseInsensitiveHash,
        CaseInsensitiveEqual
    > symbols_;

public:
    bool Define(const std::string& name, uint16_t val) {
        auto it = symbols_.find(name);
        if (it == symbols_.end()) {
            symbols_[name] = val;
            return true;
        }
        if (it->second != val) {
            it->second = val;
            return true;
        }
        return false;
    }

    [[nodiscard]] std::optional<uint16_t> Lookup(std::string_view name) const {
        if (auto it = symbols_.find(name); it != symbols_.end()) {
            return it->second;
        }
        return std::nullopt;
    }
};


inline std::optional<int64_t> EvaluateExpr(const ExprNode* node, const SymbolTable& symbols) {
    if (!node) return std::nullopt;

    if (auto num = dynamic_cast<const NumberExpr*>(node)) return num->value;

    if (auto sym = dynamic_cast<const SymbolExpr*>(node)) {
        auto val = symbols.Lookup(sym->name);
        if (val) return static_cast<int64_t>(*val);
        return std::nullopt;
    }

    if (auto un = dynamic_cast<const UnaryExpr*>(node)) {
        if (!un->operand) return std::nullopt;
        auto val = EvaluateExpr(un->operand.get(), symbols);
        if (!val) return std::nullopt;
        switch ((TokenKind)un->op) {
        case TokenKind::Minus:
            return -(*val);
        case TokenKind::Plus:
            return +(*val);
        case TokenKind::Tilde:
            return ~(*val);
        case TokenKind::Bang:
            return !(*val);
        case TokenKind::LowByte:
            return (*val) & 0xFF;
        case TokenKind::HighByte:
            return ((*val) >> 8) & 0xFF;
        default:
            return std::nullopt;
        }
    }

    if (auto bin = dynamic_cast<const BinaryExpr*>(node)) {
        if (!bin->lhs || !bin->rhs) return std::nullopt;
        auto lhs = EvaluateExpr(bin->lhs.get(), symbols);
        auto rhs = EvaluateExpr(bin->rhs.get(), symbols);
        if (!lhs || !rhs) return std::nullopt;

        switch ((TokenKind)bin->op) {
        case TokenKind::Plus:
            return *lhs + *rhs;
        case TokenKind::Minus:
            return *lhs - *rhs;
        case TokenKind::Star:
            return *lhs * *rhs;
        case TokenKind::Slash:
            return (*rhs != 0) ? *lhs / *rhs : 0;
        case TokenKind::Percent:
            return (*rhs != 0) ? *lhs % *rhs : 0;
        case TokenKind::Ampersand:
            return *lhs & *rhs;
        case TokenKind::Pipe:
            return *lhs | *rhs;
        case TokenKind::Caret:
            return *lhs ^ *rhs;
        case TokenKind::Shl:
            return *lhs << *rhs;
        case TokenKind::Shr:
            return *lhs >> *rhs;
        default:
            return std::nullopt;
        }
    }

    return std::nullopt;
}

// ============================================================================
// 3. Intermediate Representation (IR) Statements
// ============================================================================

struct Statement {
    virtual ~Statement() = default;
};

struct LabelStatement : Statement {
    std::string name;
    explicit LabelStatement(std::string name) : name(std::move(name)) {}
};

struct InstructionStatement : Statement {
    uint16_t address{0};
    std::string mnemonic;
    RULE_TYPE mode{RULE_TYPE::Op_Implied};
    std::unique_ptr<ExprNode> operand{nullptr};
    std::vector<uint8_t> bytes;

    InstructionStatement(std::string m, RULE_TYPE mode, std::unique_ptr<ExprNode> op)
        : mnemonic(std::move(m)), mode(mode), operand(std::move(op)) {}
};
struct OrgStatement : Statement {
    std::unique_ptr<ExprNode> address_expr;
    explicit OrgStatement(std::unique_ptr<ExprNode> expr) : address_expr(std::move(expr)) {}
};

struct EquStatement : Statement {
    std::string name;
    std::unique_ptr<ExprNode> value_expr;
    EquStatement(std::string n, std::unique_ptr<ExprNode> expr)
        : name(std::move(n)), value_expr(std::move(expr)) {}
};

enum class DataWidth { Byte, Word };

struct DataStatement : Statement {
    DataWidth width{DataWidth::Byte};
    std::vector<std::unique_ptr<ExprNode>> elements;

    DataStatement(DataWidth w, std::vector<std::unique_ptr<ExprNode>> elems)
        : width(w), elements(std::move(elems)) {}
};

// ============================================================================
// 4. Parser (Token Stream -> IR Statements)
// ============================================================================

class AssemblerParser {
    std::vector<PasmTokenizer::Token> tokens_;
    size_t index_{0};
    PasmTokenizer::Token Tok;

private:
bool IsMacro(std::string name) const {
    std::transform(name.begin(), name.end(), name.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return macros_.find(name) != macros_.end();
}

int prTok(std::string msg=" AssemblerParser ") {
	auto text = Tok.text;
	auto id = Tok.id;
	if (id == (int)TokenKind::Newline) text = "[\\n]";
	if (id == (int)TokenKind::Eof) text = "[EOF]";
	if (id == (int)TokenKind::Invalid) text = "[INVALID]";
		
	std::cout << msg << " '" << text << "' [" << tokmap[(TokenKind)id] << "]\n";
	return 0; 
}

int prProcTok(std::string msg="") {
	auto text = Tok.text;
	auto id = Tok.id;
	if (id == (int)TokenKind::Newline) text = "[\\n]";
	if (id == (int)TokenKind::Eof) text = "[EOF]";
	if (id == (int)TokenKind::Invalid) text = "[INVALID]";
		
	std::cout << " PROCESS " << msg << " '" << text << "' [" << tokmap[(TokenKind)id] << "]\n";
	return 0; 
}
public:
    explicit AssemblerParser(std::vector<PasmTokenizer::Token> tokens) : tokens_(std::move(tokens)) {
        if (!tokens_.empty()) Tok = tokens_[0];
    }

    PasmTokenizer::Token ConsumeToken() {
        PasmTokenizer::Token prev = Tok;
        index_++;
        Tok = (index_ < tokens_.size()) ? tokens_[index_] : PasmTokenizer::Token{static_cast<int>(TokenKind::Eof), ""};
        SkipWs();
        return prev;
    }

    [[nodiscard]] bool TokIs(TokenKind kind) const {
        return Tok.is(static_cast<int>(kind));
    }

    [[nodiscard]] bool TokAheadIs(TokenKind kind, int n = 1) const {
        auto temp_index = index_;
        auto count = 0;
        while (temp_index + 1 < tokens_.size()) {
            if (tokens_[temp_index + 1].is(static_cast<int>(TokenKind::Ws))) {
                temp_index++;
                continue;
            }
            count++;
            if (count == n) {
                return (tokens_[temp_index + 1].is(static_cast<int>(kind)));
            }
            temp_index++;
        }
        return false;
    }

    void SkipWs() {
        while (TokIs(TokenKind::Ws)) {
            ConsumeToken();
        }
    }

    std::vector<std::unique_ptr<Statement>> ParseProgram() {
        std::vector<std::unique_ptr<Statement>> statements;

        auto line = 1;
		bool display_tok = true;
        while (!TokIs(TokenKind::Eof)) { 
			
			if (display_tok) {
				std::cout << "index = " << index_;
				prTok();
			}

            // check for a comment
            if (TokIs(TokenKind::Semicolon)) {
				prProcTok();
                while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                    ConsumeToken();
                }
                continue;
            }

            // end of line
            if (TokIs(TokenKind::Newline)) {
            	prProcTok();
				ConsumeToken();
                line++;
                continue;
            }

            // 1. Symbol definition / EQU (e.g. SCREEN = $0400)
            if (TokIs(TokenKind::Identifier) && TokAheadIs(TokenKind::Equal)) {
				prProcTok();
                std::string sym_name = ConsumeToken().text;
                ConsumeToken(); // consume '='
                auto val_expr = ParseExpression();
                statements.push_back(std::make_unique<EquStatement>(sym_name, val_expr.release()));
                continue;
            }

            // 2. PC Assignment (e.g., * = $C000)
            if (TokIs(TokenKind::Star) && TokAheadIs(TokenKind::Equal)) {
				prProcTok();
				ConsumeToken(); // consume '*'
                ConsumeToken(); // consume '='
                auto addr_expr = ParseExpression();
                statements.push_back(std::make_unique<OrgStatement>(addr_expr.release()));
                continue;
            }

   
			// 3. Labels
            // Ensure we don't accidentally treat a macro invocation as a label
            if (TokIs(TokenKind::Label) || (TokIs(TokenKind::Identifier) && !IsMacro(Tok.text))) {
     			prProcTok();

				std::string name = Tok.text;
                if (!name.empty() && name.back() == ':')
                    name.pop_back();
                Tok.id = static_cast<int>(TokenKind::Label);
                statements.push_back(std::make_unique<LabelStatement>(std::move(name)));
                ConsumeToken();
                continue;
            }

            // 4. Directives (.org, .byte, .word)
            if (TokIs(TokenKind::Directive)) {
				prProcTok();

                PasmTokenizer::Token dir_tok = ConsumeToken();
                std::string dir = dir_tok.text;
                std::transform(dir.begin(), dir.end(), dir.begin(),
                [](unsigned char c) {
                    return std::tolower(c);
                });

                if (dir == ".org") {
                    auto addr_expr = ParseExpression();
                    statements.push_back(std::make_unique<OrgStatement>(addr_expr.release()));
                }
                else if (dir == ".byte" || dir == ".word") {
                    DataWidth w = (dir == ".byte") ? DataWidth::Byte : DataWidth::Word;
                    std::vector<std::unique_ptr<ExprNode>> elems;

                    do {
                        if (TokIs(TokenKind::Comma)) ConsumeToken();
                        auto expr = ParseExpression();
                        if (expr.isUsable()) elems.push_back(expr.release());
                    } while (TokIs(TokenKind::Comma));

                    statements.push_back(std::make_unique<DataStatement>(w, std::move(elems)));
                }
                
                else if (dir == ".macro") {
                    PasmTokenizer::Token name_tok = ConsumeToken();
                    if (!name_tok.is(static_cast<int>(TokenKind::Identifier))) {
						throw std::runtime_error(".macro expected name");
					}

					// skip to EOL
                    while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                        ConsumeToken();
                    }
					// consume newline
					ConsumeToken();

                    MacroDef def;
                    def.name = name_tok.text;

                    // Slurp all tokens until .endm directive is reached
                    auto slurp = ConsumeToken();
                    while (!(slurp.is(static_cast<int>(TokenKind::Directive)) && slurp.text == ".endm")) {
						def.body_tokens.push_back(slurp);
                        slurp = ConsumeToken();
                    }

                    if (TokIs(TokenKind::Eof)) {
                        throw std::runtime_error("Expected .endm to close macro definition");
                    }
                    
                    // Store in registry
					std::string lower_key(def.name);
    				std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
					    [](unsigned char c) {
        					return static_cast<char>(std::tolower(c));
  					});
                    std::cout << "saving macro " << lower_key << "\n";
					macros_[lower_key] = std::move(def);
                    
                    // Macro definitions emit no statements into the AST
                    continue;
                }
                continue;
            }

			// 4.5 Macro Expansion
			if (TokIs(TokenKind::Identifier) && IsMacro(Tok.text)) {

				prProcTok();

				// 1. Save the start position of the macro call in the token stream
				size_t start_idx = index_;

				std::string mac_name = ConsumeToken().text;
				
				std::cout << "\n\nexpanding macro " << mac_name << "\n\n";
				std::cout << "index " << start_idx << "\n";
				
				std::string lower_key = mac_name;
				std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
					[](unsigned char c) { return static_cast<char>(std::tolower(c)); });
				
				const MacroDef& mac = macros_[lower_key];

				// Parse the arguments passed to the macro call
				std::vector<std::vector<PasmTokenizer::Token>> args;
				std::vector<PasmTokenizer::Token> current_arg;
				
				while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof) && !TokIs(TokenKind::Semicolon)) {
					if (TokIs(TokenKind::Comma)) {
						args.push_back(current_arg);
						current_arg.clear();
						ConsumeToken();
					} else {
						current_arg.push_back(ConsumeToken());
					}
				}
				if (!current_arg.empty()) {
					args.push_back(current_arg);
				}

				if (TokIs(TokenKind::Newline)) {
					line++;
					ConsumeToken();
				}

				// 2. Save the end position after consuming the invocation line
				size_t end_idx = index_;

				// Positional Token Substitution
				std::vector<PasmTokenizer::Token> expanded_tokens;
				for (size_t i = 0; i < mac.body_tokens.size(); ++i) {
					const auto& body_tok = mac.body_tokens[i];

					bool substituted = false;
					
					// Look for positional identifiers like \1, \2, \10
					if (body_tok.text.size() >= 2 && body_tok.text[0] == '\\') {
						auto valid = true;
						int arg_idx = 0;
						
						for (size_t j = 1; j < body_tok.text.size(); ++j) {
							if (!std::isdigit(body_tok.text[j])) {
								valid = false;
								break;
							}
							arg_idx *= 10;
							arg_idx += body_tok.text[j] - '0';
						}
						
						if (valid) {
							arg_idx -= 1; 

							if (arg_idx >= 0 && arg_idx < static_cast<int>(args.size())) {
								for (auto a : args[arg_idx]) {
									expanded_tokens.push_back(a);
								}
								substituted = true;
							} else {
								throw std::runtime_error("Macro call missing argument for positional parameter " + body_tok.text);
							}
						}
					}
					
					if (!substituted) {
						expanded_tokens.push_back(body_tok);
					}
				}


				// 3. Remove the original invocation tokens (testm 50,LOOP\n)
				std::cout << "erasing " << start_idx << " to " << end_idx << "\n";
				tokens_.erase(tokens_.begin() + start_idx, tokens_.begin() + end_idx);

				// 4. Insert expanded tokens into the exact spot of the macro call
				std::cout << "inserting " << start_idx << "\n";
				tokens_.insert(tokens_.begin() + start_idx, expanded_tokens.begin(), expanded_tokens.end());
				
				// 5. Reset index_ and Tok back to start_idx to process the injected tokens
				index_ = start_idx -1;
				ConsumeToken();
				continue;
			}

			// 5. Opcodes
			if (TokIs(TokenKind::Opcode)) {
				
				prProcTok();
				
				PasmTokenizer::Token opcode_tok = ConsumeToken();
				std::string mnemonic = opcode_tok.text;
				RULE_TYPE mode = RULE_TYPE::Op_Implied;
				ExprResult operand_expr;

				if (TokIs(TokenKind::Hash)) {
					prTok();

					// Immediate: #expr
					ConsumeToken();
					mode = RULE_TYPE::Op_Immediate;
					operand_expr = ParseExpression();
				} else if (TokIs(TokenKind::Newline) || TokIs(TokenKind::Eof) || TokIs(TokenKind::Semicolon)) {
					// Implied
					mode = RULE_TYPE::Op_Implied;
				} else if (TokIs(TokenKind::Identifier) && (Tok.text == "a" || Tok.text == "A")) {
					// Accumulator: LSR A
					ConsumeToken();
					mode = RULE_TYPE::Op_Accumulator;
				} else if (TokIs(TokenKind::LParen)) {
					// Indirect modes
					ConsumeToken(); // Consume '('
					operand_expr = ParseExpression();
					
					if (TokIs(TokenKind::Comma)) {
						// Indexed Indirect: (expr, X)
						ConsumeToken(); // Consume ','
						if (TokIs(TokenKind::Identifier) && (Tok.text == "x" || Tok.text == "X")) {
							ConsumeToken(); // Consume 'X'
							if (TokIs(TokenKind::RParen)) {
								ConsumeToken(); // Consume ')'
								mode = RULE_TYPE::Op_IndirectX;
							} else {
								throw std::runtime_error("Expected ')' for Indirect X addressing");
							}
						} else {
							throw std::runtime_error("Expected 'X' for Indirect X addressing");
						}
					} else if (TokIs(TokenKind::RParen)) {
						ConsumeToken(); // Consume ')'
						if (TokIs(TokenKind::Comma)) {
							// Indirect Indexed: (expr), Y
							ConsumeToken(); // Consume ','
							if (TokIs(TokenKind::Identifier) && (Tok.text == "y" || Tok.text == "Y")) {
								ConsumeToken(); // Consume 'Y'
								mode = RULE_TYPE::Op_IndirectY;
							} else {
								throw std::runtime_error("Expected 'Y' for Indirect Y addressing");
							}
						} else {
							// Standard Indirect: (expr) - used by JMP
							mode = RULE_TYPE::Op_Indirect;
						}
					} else {
						throw std::runtime_error("Malformed indirect addressing mode");
					}
				} else {
					// Absolute, Absolute X/Y, Relative, or Zero-Page
					operand_expr = ParseExpression();
					if (TokIs(TokenKind::Comma)) {
						ConsumeToken();
						if (TokIs(TokenKind::Identifier) && (Tok.text == "x" || Tok.text == "X")) {
							ConsumeToken();
							mode = RULE_TYPE::Op_AbsoluteX;
						} else if (TokIs(TokenKind::Identifier) && (Tok.text == "y" || Tok.text == "Y")) {
							ConsumeToken();
							mode = RULE_TYPE::Op_AbsoluteY;
						} else {
							throw std::runtime_error("Expected X or Y register after comma");
						}
					} else {
						mode = DeduceMemoryMode(mnemonic);
					}
				}

				std::cout << "creating InstructionStatement [" << mnemonic << "] mode [" << mode << "]\n";
				
				statements.push_back(std::make_unique<InstructionStatement>(
					mnemonic, mode, std::unique_ptr<ExprNode>(operand_expr.release())
				));
				continue;
			}			
            std::cout << "Invalid token " << tokmap[static_cast<TokenKind>(Tok.id)] << "\n";
            ConsumeToken();
        }

        return statements;
    }

private:
    ExprResult ParseExpression(int min_prec = 0) {
        ExprResult lhs = ParsePrefixExpression();
        if (lhs.isInvalid()) return lhs;

        while (true) {
            OpPrecedence op_info = GetBinaryPrecedence(Tok.id);
            if (op_info.prec < min_prec) break;

            PasmTokenizer::Token op_tok = ConsumeToken();
            int next_min_prec = (op_info.assoc == Associativity::Left)
                                ? op_info.prec + 1 : op_info.prec;

            ExprResult rhs = ParseExpression(next_min_prec);
            if (rhs.isInvalid()) return ExprResult::Error();

            lhs = ExprResult(std::make_unique<BinaryExpr>(
                                 op_tok.id, lhs.release(), rhs.release()
                             ));
        }
        return lhs;
    }

    ExprResult ParsePrefixExpression() {
        if (TokIs(TokenKind::Number)) {
            PasmTokenizer::Token t = ConsumeToken();
            int64_t val = 0;
            try {
                if (t.text.starts_with("$") && t.text.size() > 1) {
                    val = std::stoll(t.text.substr(1), nullptr, 16);
                } else if (t.text.starts_with("%") && t.text.size() > 1) {
                    val = std::stoll(t.text.substr(1), nullptr, 2);
                } else if (!t.text.empty()) {
                    val = std::stoll(t.text);
                }
            } catch (...) {
                val = 0;
            }
            return ExprResult(std::make_unique<NumberExpr>(val));
        }

        if (TokIs(TokenKind::Identifier)) {
            PasmTokenizer::Token t = ConsumeToken();
            return ExprResult(std::make_unique<SymbolExpr>(t.text));
        }

        if (TokIs(TokenKind::LParen)) {
            ConsumeToken();
            ExprResult expr = ParseExpression(0);
            if (TokIs(TokenKind::RParen)) ConsumeToken();
            return expr;
        }

        if (IsUnaryPrefix(Tok.id)) {
            PasmTokenizer::Token op_tok = ConsumeToken();
            ExprResult operand = ParseExpression(50);
            return ExprResult(std::make_unique<UnaryExpr>(op_tok.id, operand.release()));
        }

        return ExprResult::Error();
    }

    static OpPrecedence GetBinaryPrecedence(int kind) {
        switch ((TokenKind)kind) {
        case TokenKind::Equal:
            return { 5,  Associativity::Right };
        case TokenKind::Pipe:
            return { 10, Associativity::Left  };
        case TokenKind::Caret:
            return { 15, Associativity::Left  };
        case TokenKind::Ampersand:
            return { 20, Associativity::Left  };
        case TokenKind::Shl:
        case TokenKind::Shr:
            return { 25, Associativity::Left  };
        case TokenKind::Plus:
        case TokenKind::Minus:
            return { 30, Associativity::Left  };
        case TokenKind::Star:
        case TokenKind::Slash:
        case TokenKind::Percent:
            return { 40, Associativity::Left  };
        default:
            return { -1, Associativity::Left  };
        }
    }

    static bool IsUnaryPrefix(int k) {
        return k == static_cast<int>(TokenKind::LowByte) || k == static_cast<int>(TokenKind::HighByte) ||
               k == static_cast<int>(TokenKind::Minus)   || k == static_cast<int>(TokenKind::Plus)     ||
               k == static_cast<int>(TokenKind::Tilde)   || k == static_cast<int>(TokenKind::Bang);
    }

    RULE_TYPE DeduceMemoryMode(std::string mnemonic) const {
        std::transform(mnemonic.begin(), mnemonic.end(), mnemonic.begin(),
        [](unsigned char c) {
            return std::tolower(c);
        });

        const OpCodeInfo* info = FindOpCodeInfo(mnemonic);
        if (info->mode_to_opcode.contains(RULE_TYPE::Op_Relative)) {
            return RULE_TYPE::Op_Relative;
        }
        return RULE_TYPE::Op_Absolute;
    }
};

// ============================================================================
// 5. Multi-Pass Assembler Engine
// ============================================================================

class MultiPassAssembler {
    SymbolTable symbols_;
    uint16_t start_pc_{0xC000};

public:
    explicit MultiPassAssembler(uint16_t start_pc = 0xC000) : start_pc_(start_pc) {}

    void Assemble(std::vector<std::unique_ptr<Statement>>& statements) {
        size_t pass = 1;
        bool symbols_changed = true;
        const size_t max_passes = 10;

        std::cout << "--- Starting Multi-Pass Symbol Resolution ---\n";

        while (symbols_changed && pass <= max_passes) {
            symbols_changed = ResolutionPass(statements);
            std::cout << "Pass " << pass << " complete. "
                      << (symbols_changed ? "Symbols modified (needs another pass)." : "Symbols stable.") << "\n";
            pass++;
        }

        if (symbols_changed) {
            throw std::runtime_error("Symbol resolution failed to converge after " + std::to_string(max_passes) +" passes.");
            return;
        }

        EmitFinalPass(statements);
    }

private:
    bool ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements) {
        uint16_t pc = start_pc_;
        bool changed = false;
        std::vector<std::unique_ptr<Statement>> new_statements;
        new_statements.reserve(statements.size());

        // Inversion lookup table for 6502 branches
        static const std::unordered_map<std::string, std::string> inverted_branches = {
            {"bne", "beq"}, {"beq", "bne"},
            {"bcc", "bcs"}, {"bcs", "bcc"},
            {"bvc", "bvs"}, {"bvs", "bvc"},
            {"bmi", "bpl"}, {"bpl", "bmi"}
        };

        for (auto& stmt : statements) {
            if (!stmt) continue;

            if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
                changed |= symbols_.Define(lbl->name, pc);
                new_statements.push_back(std::move(stmt));
            }
            else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
                if (org->address_expr) {
                    auto val = EvaluateExpr(org->address_expr.get(), symbols_);
                    if (val) pc = static_cast<uint16_t>(*val);
                }
                new_statements.push_back(std::move(stmt));
            }
            else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
                if (equ->value_expr) {
                    auto val = EvaluateExpr(equ->value_expr.get(), symbols_);
                    if (val) changed |= symbols_.Define(equ->name, static_cast<uint16_t>(*val));
                }
                new_statements.push_back(std::move(stmt));
            }
            else if (auto data = dynamic_cast<const DataStatement*>(stmt.get())) {
                uint16_t bytes_per_elem = (data->width == DataWidth::Byte) ? 1 : 2;
                pc += static_cast<uint16_t>(data->elements.size() * bytes_per_elem);
                new_statements.push_back(std::move(stmt));
            }
            else if (auto inst = dynamic_cast<InstructionStatement*>(stmt.get())) {
                const OpCodeInfo* info = FindOpCodeInfo(inst->mnemonic);
                if (!info) {
                    new_statements.push_back(std::move(stmt));
                    continue;
                }

                auto mode_it = info->mode_to_opcode.find(inst->mode);
                if (mode_it != info->mode_to_opcode.end()) {

                    if (inst->mode == RULE_TYPE::Op_Relative) {
                        auto val = EvaluateExpr(inst->operand.get(), symbols_);
                        if (val.has_value()) {
                            auto evaluated = val.value();
                            int64_t offset = evaluated - (pc + 2);

                            if (offset < -128 || offset > 127) {
                                auto it = inverted_branches.find(inst->mnemonic);
                                if (it != inverted_branches.end()) {
                                    std::cout << "Warning: Branch out of range for '" << inst->mnemonic
                                              << "' at $" << std::hex << pc
                                              << ". Expanding to trampoline JMP.\n" << std::dec;

                                    // 1. Create the JMP statement FIRST by moving the original target expression
                                    auto jmp_inst = std::make_unique<InstructionStatement>(
                                        "jmp",
                                        RULE_TYPE::Op_Absolute,
                                        std::move(inst->operand) // Safely transfers the unique_ptr ownership to jmp_inst
                                    );

                                    // 2. Modify the original statement in-place into the inverted branch
                                    inst->mnemonic = it->second;
                                    inst->mode = RULE_TYPE::Op_Relative;

                                    // 3. Refill the now-empty operand with the new relative jump target (+5)
                                    inst->operand = std::make_unique<NumberExpr>(pc + 5);

                                    // 4. Push the modified branch first, followed immediately by the new JMP
                                    new_statements.push_back(std::move(stmt));
                                    new_statements.push_back(std::move(jmp_inst));

                                    pc += 5;
                                    changed = true;
                                    continue;
                                }
                            }
                        }
                    }
                    pc += GetInstructionSize(inst->mode);
                }
                new_statements.push_back(std::move(stmt));
            }
            else {
                new_statements.push_back(std::move(stmt));
            }
        }

        statements = std::move(new_statements);
        return changed;
    }

    // Helper to format 6502 operands based on addressing mode
    std::string FormatOperand(RULE_TYPE mode, int64_t val) {
        uint16_t v = static_cast<uint16_t>(val);
        switch (mode) {
        case RULE_TYPE::Op_Immediate:
            return std::format("#${:02X}", v & 0xFF);
        case RULE_TYPE::Op_ZeroPage:
            return std::format("${:02X}", v & 0xFF);
        case RULE_TYPE::Op_ZeroPageX:
            return std::format("${:02X},X", v & 0xFF);
        case RULE_TYPE::Op_ZeroPageY:
            return std::format("${:02X},Y", v & 0xFF);
        case RULE_TYPE::Op_Absolute:
            return std::format("${:04X}", v);
        case RULE_TYPE::Op_AbsoluteX:
            return std::format("${:04X},X", v);
        case RULE_TYPE::Op_AbsoluteY:
            return std::format("${:04X},Y", v);
        case RULE_TYPE::Op_Indirect:
            return std::format("(${:04X})", v);
        case RULE_TYPE::Op_IndirectX:
            return std::format("(${:02X},X)", v & 0xFF);
        case RULE_TYPE::Op_IndirectY:
            return std::format("(${:02X}),Y", v & 0xFF);
        case RULE_TYPE::Op_Relative:
            return std::format("${:04X}", v);
        case RULE_TYPE::Op_Accumulator:
            return "A";
        case RULE_TYPE::Op_Implied:
        default:
            return "";
        }
    }

    void EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements) {
        uint16_t pc = start_pc_;
        std::vector<uint8_t> binary_output;
        std::ostringstream listing;

        listing << "\n===============================================================================\n";
        listing << "                                ASSEMBLY LISTING\n";
        listing << "===============================================================================\n";
        listing << "ADDR    BYTES          STATEMENT\n";
        listing << "-------------------------------------------------------------------------------\n";

        for (const auto& stmt : statements) {
            if (!stmt) continue;

            // 1. Label Statements
            if (auto lbl = dynamic_cast<const LabelStatement*>(stmt.get())) {
                listing << std::format("${:04X}                 {}\n", pc, lbl->name);
            }
            // 2. Org Directives (*= $XXXX)
            else if (auto org = dynamic_cast<const OrgStatement*>(stmt.get())) {
                if (org->address_expr) {
                    auto val = EvaluateExpr(org->address_expr.get(), symbols_);
                    if (val) pc = static_cast<uint16_t>(*val);
                }
                listing << std::format("       {:14} *= ${:04X}\n", "", pc);
            }
            // 3. Equate Directives (NAME = $VAL)
            else if (auto equ = dynamic_cast<const EquStatement*>(stmt.get())) {
                uint16_t v = 0;
                if (equ->value_expr) {
                    auto val = EvaluateExpr(equ->value_expr.get(), symbols_);
                    v = val ? static_cast<uint16_t>(*val) : 0;
                }
                listing << std::format("${:04X}  {:14} {} = ${:04X}\n", v, "", equ->name, v);
            }
            // 4. Data Directives (.byte / .word)
            else if (auto data = dynamic_cast<const DataStatement*>(stmt.get())) {
                uint16_t current_pc = pc;
                std::vector<uint8_t> data_bytes;
                std::vector<std::string> elem_strs;

                for (const auto& expr : data->elements) {
                    if (!expr) continue;
                    auto val = EvaluateExpr(expr.get(), symbols_);
                    int64_t v = val.value_or(0);

                    if (data->width == DataWidth::Byte) {
                        uint8_t b = static_cast<uint8_t>(v & 0xFF);
                        data_bytes.push_back(b);
                        elem_strs.push_back(std::format("${:02X}", b));
                    } else {
                        uint8_t low = static_cast<uint8_t>(v & 0xFF);
                        uint8_t high = static_cast<uint8_t>((v >> 8) & 0xFF);
                        data_bytes.push_back(low);
                        data_bytes.push_back(high);
                        elem_strs.push_back(std::format("${:04X}", static_cast<uint16_t>(v & 0xFFFF)));
                    }
                }

                binary_output.insert(binary_output.end(), data_bytes.begin(), data_bytes.end());
                pc += static_cast<uint16_t>(data_bytes.size());

                // Build full statement string: e.g. ".byte $01, $02, $03"
                std::string dir_keyword = (data->width == DataWidth::Byte) ? ".byte" : ".word";
                std::string full_stmt = dir_keyword;
                for (size_t i = 0; i < elem_strs.size(); ++i) {
                    full_stmt += (i == 0 ? " " : ", ") + elem_strs[i];
                }

                // Wrap hex bytes if emitting more than 4 bytes
                constexpr size_t max_bytes_per_line = 4;
                for (size_t i = 0; i < data_bytes.size(); i += max_bytes_per_line) {
                    size_t chunk_size = std::min(max_bytes_per_line, data_bytes.size() - i);
                    uint16_t chunk_pc = static_cast<uint16_t>(current_pc + i);

                    std::string hex_str;
                    for (size_t b = 0; b < chunk_size; ++b) {
                        hex_str += std::format("{:02X} ", data_bytes[i + b]);
                    }

                    if (i == 0) {
                        listing << std::format("${:04X}  {:14} {}\n", chunk_pc, hex_str, full_stmt);
                    } else {
                        listing << std::format("${:04X}  {:14}\n", chunk_pc, hex_str);
                    }
                }
            }


        }
		
        listing << "-------------------------------------------------------------------------------\n";
        listing << std::format("Emitted {} bytes.\n", binary_output.size());

        std::cout << listing.str();
    }
};

std::string read_file_to_string(const std::string& path) {
    std::ifstream file(path, std::ios::binary);
    if (!file) throw std::runtime_error("Failed to open file: " + path);

    std::ostringstream ss;
    ss << file.rdbuf();          // reads entire file
    return ss.str();
}

// ============================================================================
// 6. Main Test Driver
// ============================================================================

int main(int argc, char* argv[])
{
    std::vector<std::string> files;
    auto arg = 1;
    while(arg < argc) {
        if (argv[arg][0] != '-') {
            files.push_back(argv[arg]);
            arg++;
        }
        else {
            std::cout << "Unknown option " << argv[arg] << "\n";
            return -1;
        }
    }
    if (files.empty()) {
       std::cout << "No input file specified.\n";
       return 1;
    }

    PasmTokenizer tokenizer;

    std::vector<PasmTokenizer::Token> tokens;
    for (auto& file: files) {
        auto source_code = read_file_to_string(file);
        auto filetokens = tokenizer.tokenize(source_code);
        tokens.insert(tokens.end(), filetokens.begin(), filetokens.end());
    }

    // Process tokens
    bool in_comment = false;
    auto line = 1;
    for (const auto& tok : tokens) {
        auto text = tok.text;
        if ((text == "\n") || (text == "\r") || (text == "\r\n")) text = "[EOL]";
        else if (text == "\t") text = "\\t";
        else if (text == " ") text = "' '";

        // Track whether we are inside a comment
        if (tok.id == static_cast<int>(TokenKind::Semicolon)) {
            in_comment = true;
#if DEBUG_TOKENS
            std::cout << "Line [" << line << "] Token: text='" << text << "' id=" << tokmap[(TokenKind)tok.id] << "\n";
#endif
        } else if (tok.id == static_cast<int>(TokenKind::Newline)) {
            in_comment = false;
            line++;
        }
        if (in_comment ) {
            continue;
        }

#if DEBUG_TOKENS
        std::cout << "Line [" << line << "] Token: text='" << text << "' id=" << tokmap[(TokenKind)tok.id] << "\n";
#endif
        if (tok.id == static_cast<int>(TokenKind::Invalid)) {

            if (!in_comment) {
                std::cerr << "Lexical Error at line " << tok.line
                    << ", col " << tok.col
                    << ": Unexpected character '" << text << "'\n";
            }
            continue;
        }
    }

    try {

        std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
        AssemblerParser parser(tokens);
        auto statements = parser.ParseProgram();

        MultiPassAssembler assembler(0xC000);
        assembler.Assemble(statements);
        std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
        std::cout << "Elapsed " << std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count() << " microseconds." << std::endl;
    }
    catch (std::exception& ex) {
        std::cerr << "Error " << ex.what() << "\n";
    }
    return 0;
}
