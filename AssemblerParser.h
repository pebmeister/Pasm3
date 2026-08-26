#pragma once

enum class Associativity { Left, Right };

struct OpPrecedence {
    int prec;
    Associativity assoc;
};

class AssemblerParser {
    std::vector<PasmTokenizer::Token> tokens_;
    size_t index_{0};
    PasmTokenizer::Token Tok;

	// Add this as a member variable in your Parser class
	std::vector<bool> ifdef_stack;

private:
    bool IsMacro(std::string name, const std::unordered_map<std::string, MacroDef>& macros_) const {
        std::transform(name.begin(), name.end(), name.begin(),
        [](unsigned char c) {
            return static_cast<char>(std::tolower(c));
        });
        return macros_.find(name) != macros_.end();
    }

    int prTok(const SourceManager &src_mgr, std::string msg="") {
        auto text = Tok.text;
        auto id = Tok.id;
        if (id == (int)TokenKind::Newline) text = "[\\n]";
        if (id == (int)TokenKind::Eof) text = "[EOF]";
        if (id == (int)TokenKind::Invalid) text = "[INVALID]";

        std::cout << msg << " '" << text << "' [" << tokmap[(TokenKind)id] << "]  :::[" << src_mgr.GetFileName(Tok.file) << " line " << Tok.line << " col " << Tok.col << "]\n";
        return 0;
    }

public:
    explicit AssemblerParser(std::vector<PasmTokenizer::Token> tokens) : tokens_(std::move(tokens)) {
        if (!tokens_.empty()) Tok = tokens_[0];
    }

    PasmTokenizer::Token ConsumeToken() {
        PasmTokenizer::Token prev = Tok;
        index_++;
        Tok = (index_ < tokens_.size()) ? tokens_[index_] : PasmTokenizer::Token{static_cast<int>(TokenKind::Eof), "", 0, 0, 0, prev.file}; 
        SkipWs();
        return prev;
    }

    [[nodiscard]] bool TokIs(TokenKind kind) const {
        return Tok.is(static_cast<int>(kind));
    }

    [[nodiscard]] bool TokAheadIs(TokenKind kind, int n = 1, bool skipwhite = true) const {
        auto temp_index = index_;
        auto count = 0;
        while (temp_index + 1 < tokens_.size()) {
            if (skipwhite) {
                if (tokens_[temp_index + 1].is(static_cast<int>(TokenKind::Ws))) {
                    temp_index++;
                    continue;
                }
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

	void SkipToElseOrEndif() {
		int depth = 1; // We are currently inside 1 unclosed .ifdef block

		while (!TokIs(TokenKind::Eof)) {
			if (TokIs(TokenKind::Directive)) {
				if (Tok.text == ".ifdef" || Tok.text == ".ifndef") {
					depth++; // Entering a nested block
				} 
				else if (Tok.text == ".endif") {
					depth--; // Exiting a block
					if (depth == 0) {
						return; // Found the matching .endif!
					}
				} 
				else if (Tok.text == ".else" && depth == 1) {
					return; // Found the matching .else at our current level!
				}
			}
			ConsumeToken(); // Skip the token entirely
		}

		throw std::runtime_error("Unexpected EOF: Missing .endif");
	}

    // Helper to check if relative label
    std::optional<int> GetRelativeLabelCount() {

        if (!TokIs(TokenKind::Plus) && !TokIs(TokenKind::Minus)) return std::nullopt;

        auto count = 1;
        auto tk = static_cast<TokenKind>(Tok.id);
        while (TokAheadIs(tk, count, false)) { // search without skipwhite dpcr
            count++;
        }

        if ((count > 1) ||
                (TokAheadIs(TokenKind::Eof, 1) ||
                 TokAheadIs(TokenKind::Newline, 1) ||
                 TokAheadIs(TokenKind::Semicolon, 1))) {
            return count;
        }

        return std::nullopt;
    }
	
    std::vector<std::unique_ptr<Statement>> ParseProgram(SourceManager &src_mgr, std::unordered_map<std::string, MacroDef>& macros_, PasmTokenizer& tokenizer) {
        std::vector<std::unique_ptr<Statement>> statements;

		SymbolTable definedSyms;
        bool display_tok = false;
        if (display_tok) {
            std::cout << "\n";
        }
        SkipWs();
        while (!TokIs(TokenKind::Eof)) {

            if (display_tok) {
                prTok(src_mgr);
            }

            // check for a comment
            if (TokIs(TokenKind::Semicolon)) {
                while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                    ConsumeToken();
                }
                continue;
            }

            // end of line
            if (TokIs(TokenKind::Newline)) {
                ConsumeToken();
                continue;
            }

            // 1. Symbol definition / EQU (e.g. SCREEN = $0400)
            if (TokIs(TokenKind::Identifier) && TokAheadIs(TokenKind::Equal)) {
                std::string sym_name = ConsumeToken().text;
                ConsumeToken(); // consume '='
                auto val_expr = ParseExpression();				
                statements.push_back(std::make_unique<EquStatement>(Tok.file, Tok.line, sym_name, val_expr.release()));
				definedSyms.Define(sym_name, 1);
                continue;
            }

            // 2. PC Assignment (e.g., * = $C000)
            if (TokIs(TokenKind::Star) && TokAheadIs(TokenKind::Equal)) {
                ConsumeToken(); // consume '*'
                ConsumeToken(); // consume '='
                auto addr_expr = ParseExpression();
                statements.push_back(std::make_unique<OrgStatement>(Tok.file, Tok.line, addr_expr.release()));
                continue;
            }

            // 3. Labels
            // Ensure we don't accidentally treat a macro invocation as a label
            if (TokIs(TokenKind::Label) || (TokIs(TokenKind::Identifier) && !IsMacro(Tok.text, macros_))) {
                std::string name = Tok.text;
                if (!name.empty() && name.back() == ':')
                    name.pop_back();
                Tok.id = static_cast<int>(TokenKind::Label);
                statements.push_back(std::make_unique<LabelStatement>(Tok.file, Tok.line, std::move(name)));
                ConsumeToken();
                continue;
            }

            // 3.5 Relative Labels
            if (TokIs(TokenKind::Minus) || TokIs(TokenKind::Plus)) {
                Tok.id = static_cast<int>(TokenKind::Label);
                statements.push_back(std::make_unique<LabelStatement>(Tok.file, Tok.line, std::move(Tok.text)));
                ConsumeToken();
                continue;
            }

            // 4. Directives (.org, .byte, .word)
            if (TokIs(TokenKind::Directive)) {

                PasmTokenizer::Token dir_tok = ConsumeToken();
                std::string dir = dir_tok.text;
                std::transform(dir.begin(), dir.end(), dir.begin(),
                [](unsigned char c) {
                    return std::tolower(c);
                });

                if (dir == ".org") {
                    auto addr_expr = ParseExpression();
                    statements.push_back(std::make_unique<OrgStatement>(Tok.file, Tok.line, addr_expr.release()));
                }
                else if (dir == ".byte" || dir == ".word") {
                    DataWidth w = (dir == ".byte") ? DataWidth::Byte : DataWidth::Word;
                    std::vector<std::unique_ptr<ExprNode>> elems;

                    do {
                        if (TokIs(TokenKind::Comma)) ConsumeToken();
						if (TokIs(TokenKind::StringLiteral)) {
							PasmTokenizer::Token str_tok = ConsumeToken();
							std::string str = str_tok.text;

							// 1. Strip surrounding quotes if your tokenizer includes them in .text
							if (str.size() >= 2 && str.front() == '"' && str.back() == '"') {
								str = str.substr(1, str.size() - 2);
							}

							// 2. Expand each character in the string to a NumberExpr
							for (size_t i = 0; i < str.length(); ++i) {
								char c = str[i];
								
								// Optional: Handle basic escape sequences (e.g., \n, \t, \0, \\)
								if (c == '\\' && i + 1 < str.length()) {
									i++;
									switch (str[i]) {
										case 'n':  c = '\n'; break;
										case 'r':  c = '\r'; break;
										case 't':  c = '\t'; break;
										case '0':  c = '\0'; break;
										case '\\': c = '\\'; break;
										case '"':  c = '"';  break;
										default:   c = str[i]; break;
									}
								}

								elems.push_back(std::make_unique<NumberExpr>(static_cast<uint8_t>(c)));
							}
						}
						else {
							auto expr = ParseExpression();
							if (expr.isUsable()) elems.push_back(expr.release());							
						}
                    } while (TokIs(TokenKind::Comma));
                    statements.push_back(std::make_unique<DataStatement>(Tok.file, Tok.line, w, std::move(elems)));
                }

                else if (dir == ".macro") {
                    PasmTokenizer::Token name_tok = ConsumeToken();
                    if (!name_tok.is(static_cast<int>(TokenKind::Identifier))) {
                        throw std::runtime_error(std::format(".macro expected name File: {} Line: {}",  src_mgr.GetFileName(name_tok.file), name_tok.line));
                    }

                    // skip to EOL
                    while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                        ConsumeToken();
                    }
                    // consume newline
                    ConsumeToken();

                    MacroDef def;
                    def.name = name_tok.text;
                    def.times_called = 0;

                    // Slurp all tokens until .endm directive is reached
                    auto slurp = ConsumeToken();
                    while (!(slurp.is(static_cast<int>(TokenKind::Directive)) && slurp.text == ".endm")) {
                        def.body_tokens.push_back(slurp);
                        slurp = ConsumeToken();
                    }

                    if (TokIs(TokenKind::Eof)) {
                        throw std::runtime_error(std::format("Expected .endm to close macro definition File: {} Line: {}", src_mgr.GetFileName(name_tok.file), name_tok.line));
                    }

                    // Store in map
                    std::string lower_key(def.name);
                    std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
                    [](unsigned char c) {
                        return static_cast<char>(std::tolower(c));
                    });
                    macros_[lower_key] = std::move(def);

					definedSyms.Define(lower_key, 1);

                    // Macro definitions emit no statements into the AST
                    continue;
                }
				
                else if (dir == ".ds") {
                    auto size_expr = ParseExpression();
                    statements.push_back(std::make_unique<DsStatement>(Tok.file, Tok.line, size_expr.release()));
                }
                
				// Inside ParseProgram() or your directive handler:
                else if (dir == ".include" || dir == ".inc") {

                    if (!TokIs(TokenKind::StringLiteral)) {
                        throw std::runtime_error(std::format("string filename after .include File: {} Line: {}", src_mgr.GetFileName(Tok.file), Tok.line));
                    }

                    std::string inc_filename = Tok.text; // e.g. "constants.inc"
                    ConsumeToken(); // consume filename string

                    inc_filename.erase(0, 1);
                    inc_filename.erase(inc_filename.size() - 1);

                    // 1. Tokenize the included file using SourceManager
                    auto inc_tokens = LoadAndTokenizeFile(inc_filename, src_mgr, tokenizer);

                    // 2. Recursively parse the included tokens into AST statements
                    AssemblerParser parser(inc_tokens);
                    auto inc_statements = parser.ParseProgram(src_mgr,  macros_, tokenizer);

                    // 3. Insert the included statements directly inline
                    for (auto& stmt : inc_statements) {
                        statements.push_back(std::move(stmt));
                    }

                    continue;
                }
                else if (dir == ".print") {
                    if (!TokIs(TokenKind::Identifier)) {
                        throw std::runtime_error(std::format("Expected Identifier after .print File: {} Line: {}", src_mgr.GetFileName(Tok.file), Tok.line));
                    }
					
					PrintCmd cmd;
					std::string lower_opt = Tok.text;
					
					std::transform(lower_opt.begin(), lower_opt.end(), lower_opt.begin(),
					[](unsigned char c) {
						return static_cast<char>(std::tolower(c));
					});
									
					if (lower_opt  == "on") cmd = PrintCmd::on;
					else if (lower_opt == "off")  cmd = PrintCmd::off;
					else if (lower_opt == "push") cmd = PrintCmd::push;
					else if (lower_opt == "pop")  cmd = PrintCmd::pop;
					else {
						throw std::runtime_error(std::format("Unknown option for .print File: {} Line: {}", src_mgr.GetFileName(Tok.file), Tok.line));
					}
                    statements.push_back(std::make_unique<PrintStatement>(Tok.file, Tok.line, cmd));     
                    ConsumeToken(); 
					continue;
                }
				else if ((dir == ".ifdef") || (dir == ".ifndef")) {
					
					if (!TokIs(TokenKind::Identifier)) {
						throw std::runtime_error(std::format(
							"Expected Identifier after .ifdef File: {} Line: {}", 
							src_mgr.GetFileName(Tok.file), Tok.line
						));
					}
					
					auto sym = definedSyms.Lookup(Tok.text);
					ConsumeToken(); // Consume the identifier token

					if ((sym.has_value() && dir == ".ifdef") || (!sym.has_value() && dir == ".ifndef")) {                    
						// Condition is TRUE. 
						// Keep parsing normally, but record that this block succeeded
						// so we know to skip the .else later.
						ifdef_stack.push_back(true);
					} 
					else {
						// Condition is FALSE.
						// Skip all tokens until we hit .else or .endif
						SkipToElseOrEndif();

						// If we landed on an .else, we must parse the else block normally.
						// Record that the IF portion was false.
						if (Tok.text == ".else") {
							ifdef_stack.push_back(false);
							ConsumeToken(); // Consume ".else"
						} 
						// If we landed on .endif, just consume it and don't push to stack.
						else if (Tok.text == ".endif") {
							ConsumeToken(); // Consume ".endif"
						}
					}
				}
				else if (dir == ".else") {
					if (ifdef_stack.empty()) {
						throw std::runtime_error("Unexpected .else without .ifdef");
					}

					bool if_was_true = ifdef_stack.back();
					ConsumeToken(); // Consume ".else"

					if (if_was_true) {
						// The IF block executed, so we MUST skip this ELSE block
						SkipToElseOrEndif(); // Will land on .endif
						ConsumeToken();      // Consume ".endif"
						ifdef_stack.pop_back(); // Close the block
					} else {
						// The IF block was false, so we are currently parsing this ELSE block.
						// Just let the parser continue naturally!
					}
				}
				else if (dir == ".endif") {
					if (ifdef_stack.empty()) {
						throw std::runtime_error("Unexpected .endif without .ifdef");
					}
					ConsumeToken(); // Consume ".endif"
					ifdef_stack.pop_back(); // Close the block
				}
				
				
                else {
                    std::cout << "Warning Unknown directive '" << dir << "'  File: " << src_mgr.GetFileName(dir_tok.file) << " Line: " << dir_tok.line << "\n";
                }

                continue;
            }

            // 4.5 Macro Expansion
            if (TokIs(TokenKind::Identifier) && IsMacro(Tok.text, macros_)) {

                auto mac_call_tok = Tok;

                // 1. Save the start position of the macro call in the token stream
                size_t start_idx = index_;

                std::string mac_name = ConsumeToken().text;

                std::string lower_key = mac_name;
                std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
                [](unsigned char c) {
                    return static_cast<char>(std::tolower(c));
                });

                MacroDef& mac = macros_[lower_key];
                mac.times_called++;

                // Parse the arguments passed to the macro call
                std::vector<std::vector<PasmTokenizer::Token>> args;
                std::vector<PasmTokenizer::Token> current_arg;

                while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof) && !TokIs(TokenKind::Semicolon)) {
                    if (TokIs(TokenKind::Comma)) {
                        args.push_back(current_arg);
                        current_arg.clear();
                        ConsumeToken();
                    } else {
						auto tok = ConsumeToken();
                        current_arg.push_back(tok);
                    }
                }
                if (!current_arg.empty()) {
                    args.push_back(current_arg);
                }

                if (TokIs(TokenKind::Newline)) {
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
                    if (body_tok.text.size() >= 2) {

                        if (body_tok.text[0] == '\\') {
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
                                        a.file = Tok.file;
                                        a.line = Tok.line;
                                        expanded_tokens.push_back(a);
                                    }
                                    substituted = true;
                                } else {
                                    throw std::runtime_error( std::format("Macro call missing argument for positional parameter {} File: {} Line: {}",
                                                                          body_tok.text, src_mgr.GetFileName(mac_call_tok.file), mac_call_tok.line));
                                }
                            }
                        }
                        else if (body_tok.text[0] == '@') {
							auto expTok = body_tok;
							expTok.file = Tok.file;
							expTok.line = Tok.line;
							expTok.text = "@" + mac_call_tok.text + "_" + std::to_string(mac.times_called) + "_" + body_tok.text.substr(1);
							expanded_tokens.push_back(expTok);
							substituted = true;
                        }
                    }

                    if (!substituted) {
                        auto expTok = body_tok;
                        expTok.file = Tok.file;
                        expTok.line = Tok.line;
                        expanded_tokens.push_back(expTok);
                    }
                }

                // 3. Remove the original invocation tokens (testm 50,LOOP\n)
                tokens_.erase(tokens_.begin() + start_idx, tokens_.begin() + end_idx);

                // 4. Insert expanded tokens into the exact spot of the macro call
                tokens_.insert(tokens_.begin() + start_idx, expanded_tokens.begin(), expanded_tokens.end());

                // 5. Reset index_ and Tok back to start_idx to process the injected tokens
                index_ = start_idx -1;
                ConsumeToken();
                continue;
            }

            // 5. Opcodes
            if (TokIs(TokenKind::Opcode)) {

                PasmTokenizer::Token opcode_tok = ConsumeToken();
                std::string mnemonic = opcode_tok.text;
                RULE_TYPE mode = RULE_TYPE::Op_Implied;
                ExprResult operand_expr;

                if (TokIs(TokenKind::Hash)) {
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
                                throw std::runtime_error(std::format("Expected ')' for Indirect X addressing File: {} Line: {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
                            }
                        } else {
                            throw std::runtime_error(std::format("Expected 'X' for Indirect X addressing File: {} Line: {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
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
                                throw std::runtime_error(std::format("Expected 'Y' for Indirect Y addressing File: {} Line: {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
                            }
                        } else {
                            // Standard Indirect: (expr) - used by JMP
                            mode = RULE_TYPE::Op_Indirect;
                        }
                    } else {
                        throw std::runtime_error(std::format("Malformed indirect addressing mode File: {} Line {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
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
                            throw std::runtime_error(std::format("Expected X or Y register after comma File: {} Line: {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
                        }
                    } else {
                        mode = DeduceMemoryMode(mnemonic);
                    }
                }

                statements.push_back(std::make_unique<InstructionStatement>(
                                         opcode_tok.file, opcode_tok.line, mnemonic, mode, std::unique_ptr<ExprNode>(operand_expr.release())
                                     ));
                continue;
            }
            std::cout << "Invalid token " << tokmap[static_cast<TokenKind>(Tok.id)] << " File: " << src_mgr.GetFileName(Tok.file) << " Line: " << Tok.line << "\n";
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
                } else if (t.text.starts_with("'") && t.text.ends_with("'") && t.text.size() == 3) {
                    val = static_cast<int64_t>(t.text[1]);					
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

        auto anon_count = GetRelativeLabelCount();
        if (anon_count.has_value()) {
            auto foward = Tok.id == static_cast<int>(TokenKind::Plus);
            auto count = anon_count.value();
            for (auto i=0; i < count; ++i) {
                ConsumeToken();
            }
            return ExprResult(std::make_unique<AnonLblExpr>(foward, count));
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
