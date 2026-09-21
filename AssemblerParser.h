#pragma once

/**
 * @author Paul Baxter
 */

#include <filesystem>
#include <fstream>
#include <iostream>
#include <stack>

#include "options.h"


namespace fs = std::filesystem; ///< file system namespace

/**
 * @brief Specifies the processing stage for conditional assembly directives.
 */
enum class CondKind {
    IfDef,  ///< Handled at compile/parse time via token skipping (e.g., .ifdef / .ifndef).
    IfNode  ///< Handled at runtime/AST generation via IfStatement nodes (e.g., .if).
};

/**
 * @brief Represents operator associativity for expression parsing.
 */
enum class Associativity { 
    Left,  ///< Left-to-right operator associativity.
    Right  ///< Right-to-left operator associativity.
};

/**
 * @brief Defines operator precedence and associativity rules for parser expressions.
 */
struct OpPrecedence {
    int prec;           ///< Precedence level (higher values indicate higher binding priority).
    Associativity assoc; ///< Operator associativity direction.
};

/**
 * @class AssemblerParser
 * @brief Parses token streams from assembly source code into Abstract Syntax Tree (AST) statements.
 *
 * Handles assembly directives, macro expansions, conditional assembly blocks, 
 * label declarations, symbol definitions, and instruction parsing.
 */
class AssemblerParser {
private:
    std::vector<PasmTokenizer::Token> tokens_; ///< Stream of tokens to be parsed.

    /**
     * @brief Context frame tracking nested conditional assembly directives (.if / .ifdef).
     */
    struct CondFrame {
        CondKind kind;     ///< The type of conditional directive active in this frame.
        bool if_was_true;  ///< Indicates if the preceding branch evaluated to true (determines if .else should execute).
    };

    std::vector<CondFrame> cond_stack; ///< Stack tracking active nested conditional frames.
    size_t index_{0};                  ///< Current index position within the token stream.
    PasmTokenizer::Token Tok;          ///< Current active lookahead token.

    std::vector<bool> ifdef_stack;     ///< Legacy stack tracking boolean evaluation states for conditional blocks.

    Options options;                   ///< Global assembly toolchain options and configuration settings.

    /**
     * @brief Checks whether a given identifier name matches a defined macro.
     * @param name Name of the identifier to query (case-insensitive).
     * @param macros_ Map of defined macros in the current compilation context.
     * @return True if the identifier represents a registered macro, false otherwise.
     */
    bool IsMacro(std::string name, const std::unordered_map<std::string, MacroDef>& macros_) const {
        std::transform(name.begin(), name.end(), name.begin(),
        [](unsigned char c) {
            return static_cast<char>(std::tolower(c));
        });
        return macros_.find(name) != macros_.end();
    }

    /**
     * @brief Prints diagnostic details for the current lookahead token to stdout.
     * @param src_mgr SourceManager instance used to resolve the source filename.
     * @param msg Optional custom label or prefix message to display alongside output.
     * @return Always returns 0.
     */
    int prTok(const SourceManager &src_mgr, std::string msg="") {
        auto text = Tok.text;
        auto id = Tok.id;
        if (id == (int)TokenKind::Newline) text = "[\\n]";
        if (id == (int)TokenKind::Eof) text = "[EOF]";
        if (id == (int)TokenKind::Invalid) text = "[INVALID]";

        std::cout << 
            std::format("{:10} {:5} {:20} File: {} Line: {} Col: {}\n",
                msg, text, tokmap[(TokenKind)id], src_mgr.GetFileName(Tok.file), Tok.line, Tok.col);
        return 0;
    }

public:
    /**
     * @brief Constructs an AssemblerParser instance.
     * @param tokens Vector of tokens produced by the tokenizer.
     * @param opts Reference to assembler execution options and settings.
     */
    explicit AssemblerParser(std::vector<PasmTokenizer::Token> tokens, Options& opts) : tokens_(std::move(tokens)), options(opts) {
        if (!tokens_.empty()) Tok = tokens_[0];
    }

    /**
     * @brief Consumes the current token, advances the stream index, and skips trailing whitespace.
     * @return The token that was current prior to advancing.
     */
    PasmTokenizer::Token ConsumeToken() {
        PasmTokenizer::Token prev = Tok;
        index_++;
        Tok = (index_ < tokens_.size()) ? tokens_[index_] : PasmTokenizer::Token{static_cast<int>(TokenKind::Eof), "", 0, 0, 0, prev.file};
        SkipWs();
        return prev;
    }

    /**
     * @brief Checks whether the current lookahead token matches a given kind.
     * @param kind Token type enumeration value to compare against.
     * @return True if current token matches the specified kind, false otherwise.
     */
    [[nodiscard]] bool TokIs(TokenKind kind) const {
        return Tok.is(static_cast<int>(kind));
    }

    /**
     * @brief Inspects upcoming tokens without consuming them.
     * @param kind Token type enumeration value to match against.
     * @param n Number of non-whitespace tokens ahead to inspect (default is 1).
     * @param skipwhite Whether whitespace tokens should be ignored during lookahead (default is true).
     * @return True if the token at offset `n` matches `kind`, false otherwise.
     */
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

    /**
     * @brief Advances token consumption past any consecutive whitespace tokens.
     */
    void SkipWs() {
        while (TokIs(TokenKind::Ws)) {
            ConsumeToken();
        }
    }

    /**
     * @brief Skips tokens in non-matching conditional branches until reaching an associated `.else` or `.endif`.
     * @throws std::runtime_error If end-of-file (EOF) is encountered before finding a matching `.endif`.
     */
    void SkipToElseOrEndif() {
        int depth = 1;

        while (!TokIs(TokenKind::Eof)) {
            if (TokIs(TokenKind::Directive)) {
                std::string dir = Tok.text;
                std::transform(dir.begin(), dir.end(), dir.begin(),
                               [](unsigned char c) { return std::tolower(c); });

                if (dir == ".ifdef" || dir == ".ifndef" || dir == ".if") {
                    depth++;
                }
                else if (dir == ".endif") {
                    depth--;
                    if (depth == 0) {
                        return;
                    }
                }
                else if (dir == ".else" && depth == 1) {
                    return;
                }
            }
            ConsumeToken();
        }

        throw std::runtime_error("Unexpected EOF: Missing .endif");
    }
    
    /**
     * @brief Determines if the current token sequence represents a relative anonymous label reference (e.g., '+', '++', '---').
     *
     * Scans consecutive identical '+' or '-' characters without skipping whitespace to count 
     * relative forward/backward jump references.
     *
     * @return `std::optional<int>` containing the count of repeating sign tokens if a valid relative 
     *         label pattern is matched, or `std::nullopt` if it represents a standard unary/binary operator.
     */
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
                 TokAheadIs(TokenKind::Comma, 1) ||
                 TokAheadIs(TokenKind::Semicolon, 1))) {
            return count;
        }

        return std::nullopt;
    }
    
    /**
     * @brief Parses a stream of tokens into a vector of Abstract Syntax Tree (AST) statements.
     *
     * This function serves as the primary parsing loop for the assembler. It iterates through 
     * the tokens provided by the tokenizer, handling directives, macro definitions and expansions,
     * symbol definitions (`EQU`), PC assignments (`* =`), labels, control-flow statements, 
     * data declarations, and file inclusions.
     *
     * @param[in,out] src_mgr   Reference to the SourceManager used for file tracking, line numbers,
     *                          and error reporting locations.
     * @param[in,out] macros_   Unordered map storing macro definitions, keyed by lower-case macro name.
     *                          Newly encountered macros are registered here, and existing macros are expanded.
     * @param[in,out] tokenizer Reference to the tokenizer used to load and tokenize secondary 
     *                          source files during `.include` processing.
     *
     * @return std::vector<std::unique_ptr<Statement>> A list of heap-allocated AST statement nodes
     *                                                  representing the parsed program.
     *
     * @throws std::runtime_error If a syntax error, unexpected token, unclosed macro definition, 
     *                            unmatched loop/conditional block, or file reading failure occurs.
     */
    std::vector<std::unique_ptr<Statement>> ParseProgram(
        SourceManager &src_mgr, 
        std::unordered_map<std::string, MacroDef>& macros_, 
        PasmTokenizer& tokenizer) 
    {        
        std::vector<std::unique_ptr<Statement>> statements;
        std::vector<LoopStatement*> repeatStack; // Track active .repeat blocks for matching .until expressions
        
        SymbolTable definedSyms = SymbolTable("DEF");
        
        // Seed the local symbol table with CLI defined symbols (-D / --define)
        for (auto&[sym, val] : options.defined_symbols) {        
            definedSyms.Define(sym, 1);
        }
        
        bool display_tok = false;
        if (display_tok) {
            std::cout << "\n";
        }
        SkipWs();

        while (!TokIs(TokenKind::Eof)) {

            if (display_tok) {
                prTok(src_mgr);
            }

            /**
             * @section Comments & Empty Lines
             * Skip comments starting with ';' up to newline or EOF, and bypass blank lines.
             */
            if (TokIs(TokenKind::Semicolon)) {
                while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                    ConsumeToken();
                }
                continue;
            }

            if (TokIs(TokenKind::Newline)) {
                ConsumeToken();
                continue;
            }

            /**
             * @section Symbol Definition / EQU
             * Matches assignments such as `SYMBOL = <expr>`.
             */
            if (TokIs(TokenKind::Identifier) && TokAheadIs(TokenKind::Equal)) {
                std::string sym_name = ConsumeToken().text;
                ConsumeToken(); // consume '='
                auto val_expr = ParseExpression();
                statements.push_back(std::make_unique<EquStatement>(Tok.file, Tok.line, sym_name, val_expr.move()));
                definedSyms.Define(sym_name, 1);
                continue;
            }

            /**
             * @section Program Counter Assignment
             * Matches origin set syntaxes such as `* = $C000`.
             */
            if (TokIs(TokenKind::Star) && TokAheadIs(TokenKind::Equal)) {
                ConsumeToken(); // consume '*'
                ConsumeToken(); // consume '='
                auto addr_expr = ParseExpression();
                statements.push_back(std::make_unique<OrgStatement>(Tok.file, Tok.line, addr_expr.move()));
                continue;
            }

            /**
             * @section Standard & Relative Labels
             * Matches explicit labels (`label:`), implicit non-macro identifiers, and relative labels (`+`, `-`).
             */
            if (TokIs(TokenKind::Label) || (TokIs(TokenKind::Identifier) && !IsMacro(Tok.text, macros_))) {
                std::string name = Tok.text;
                if (!name.empty() && name.back() == ':')
                    name.pop_back();
                Tok.id = static_cast<int>(TokenKind::Label);
                statements.push_back(std::make_unique<LabelStatement>(Tok.file, Tok.line, std::move(name)));
                ConsumeToken();
                continue;
            }

            if (TokIs(TokenKind::Minus) || TokIs(TokenKind::Plus)) {
                Tok.id = static_cast<int>(TokenKind::Label);
                statements.push_back(std::make_unique<LabelStatement>(Tok.file, Tok.line, std::move(Tok.text)));
                ConsumeToken();
                continue;
            }

            /**
             * @section Assembler Directives
             * Handles directives including data declaration (.byte, .word, .text), memory (.org, .ds, .fill),
             * macro definition (.macro/.endm), control flow (.while/.repeat), conditionals (.ifdef/.if/.else),
             * file inclusion (.include), and variables (.var).
             */
            if (TokIs(TokenKind::Directive)) {

                PasmTokenizer::Token dir_tok = ConsumeToken();
                std::string dir = dir_tok.text;
                std::transform(dir.begin(), dir.end(), dir.begin(),
                [](unsigned char c) {
                    return std::tolower(c);
                });

                // --- .org ---
                if (dir == ".org") {
                    auto addr_expr = ParseExpression();
                    statements.push_back(std::make_unique<OrgStatement>(dir_tok.file, dir_tok.line, addr_expr.move()));
                }
                
                // --- .basic_hdr (C64 BASIC stub wrapper) ---
                else if (dir == ".basic_hdr") {
                    auto org_addr = std::make_unique<NumberExpr>(static_cast<uint16_t>(0x0801));
                    statements.push_back(std::make_unique<OrgStatement>(dir_tok.file, dir_tok.line, std::move(org_addr)));

                    std::vector<std::unique_ptr<ExprNode>> elems;
                    for (auto by: {
                                  0x0b, 0x08,             // Next line pointer ($080B)
                                  0x0a, 0x00,             // Line number 10
                                  0x9e,                   // BASIC 'SYS' token
                                  0x32, 0x30, 0x36, 0x31, // ASCII "2061" ($080D)
                                  0x00,                   // Line end
                                  0x00, 0x00              // Program end
                                }) {

                        elems.push_back(std::make_unique<NumberExpr>(static_cast<uint8_t>(by)));
                    }
                    statements.push_back(std::make_unique<DataStatement>(dir_tok.file, dir_tok.line, DataWidth::Byte, std::move(elems)));
                }
                
                // --- .byte, .db, .text, .word ---
                else if (dir == ".byte" || dir == ".db" || dir == ".text" || dir == ".word") {
                    DataWidth w = (dir == ".byte" || dir == ".db" || dir == ".text") ? DataWidth::Byte : DataWidth::Word;
                    std::vector<std::unique_ptr<ExprNode>> elems;

                    do {
                        if (TokIs(TokenKind::Comma))
                            ConsumeToken();
                        if (TokIs(TokenKind::StringLiteral)) {
                            PasmTokenizer::Token str_tok = ConsumeToken();
                            std::string str = str_tok.text;

                            if (str.size() >= 2 && str.front() == '"' && str.back() == '"') {
                                str = str.substr(1, str.size() - 2);
                            }

                            for (size_t i = 0; i < str.length(); ++i) {
                                char c = str[i];

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
                            if (expr.isUsable()) elems.push_back(expr.move());
                        }
                    } while (TokIs(TokenKind::Comma));
                    statements.push_back(std::make_unique<DataStatement>(dir_tok.file, dir_tok.line, w, std::move(elems)));
                }

                // --- .fill ---
                else if (dir == ".fill") {
                    auto byteexpr = ParseExpression();
                    ConsumeToken();
                    auto lenexpr = ParseExpression();
                    ConsumeToken();
                    statements.push_back(std::make_unique<FillStatement>(dir_tok.file, dir_tok.line, byteexpr.move(), lenexpr.move()));
                }

                // --- .macro definition ---
                else if (dir == ".macro") {
                    PasmTokenizer::Token name_tok = ConsumeToken();
                    if (!name_tok.is(static_cast<int>(TokenKind::Identifier))) {
                        throw std::runtime_error(std::format(".macro expected name File: {} Line: {}",  src_mgr.GetFileName(name_tok.file), name_tok.line));
                    }

                    while (!TokIs(TokenKind::Newline) && !TokIs(TokenKind::Eof)) {
                        ConsumeToken();
                    }
                    ConsumeToken();

                    MacroDef def;
                    def.name = name_tok.text;
                    def.times_called = 0;

                    // Slurp tokens into macro body until .endm directive
                    auto slurp = ConsumeToken();
                    while (!(slurp.is(static_cast<int>(TokenKind::Directive)) && slurp.text == ".endm")) {
                        def.body_tokens.push_back(slurp);
                        slurp = ConsumeToken();
                    }

                    if (TokIs(TokenKind::Eof)) {
                        throw std::runtime_error(std::format("Expected .endm to close macro definition File: {} Line: {}", src_mgr.GetFileName(name_tok.file), name_tok.line));
                    }

                    std::string lower_key(def.name);
                    std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(),
                    [](unsigned char c) {
                        return static_cast<char>(std::tolower(c));
                    });
                    macros_[lower_key] = std::move(def);

                    definedSyms.Define(lower_key, 1);
                    continue;
                }

                // --- .ds (define storage) ---
                else if (dir == ".ds") {
                    auto size_expr = ParseExpression();
                    statements.push_back(std::make_unique<DsStatement>(dir_tok.file, dir_tok.line, size_expr.move()));
                }
                
                // --- .break / .continue ---
                else if (dir == ".break" || dir == ".continue") {
                    statements.push_back(std::make_unique<BreakStatement>(dir_tok.file, dir_tok.line));
                }
                
                // --- .while / .wend ---
                else if (dir == ".while") {
                    auto condition_expr = ParseExpression();
                    statements.push_back(std::make_unique<LoopStatement>(
                        dir_tok.file, dir_tok.line, condition_expr.move(), 
                        StmtType::While, StmtType::Wend, 
                        true, false));
                }
                else if (dir == ".wend") {
                    statements.push_back(std::make_unique<WendStatement>(dir_tok.file, dir_tok.line));
                }
                
                // --- .repeat / .until ---
                else if (dir == ".repeat") {
                    auto loop_stmt = std::make_unique<LoopStatement>(
                        Tok.file, Tok.line, nullptr, 
                        StmtType::Repeat, StmtType::Until, 
                        false, true);

                    repeatStack.push_back(loop_stmt.get());
                    statements.push_back(std::move(loop_stmt));
                }
                else if (dir == ".until") {
                    if (repeatStack.empty()) {
                        throw std::runtime_error(std::format(".until without matching .repeat at File: {} Line: {}", 
                                                             src_mgr.GetFileName(Tok.file), Tok.line));
                    }

                    auto condition_expr = ParseExpression();
                    auto* loop_stmt = repeatStack.back();
                    repeatStack.pop_back();

                    loop_stmt->condition_expr = condition_expr.move();
                    statements.push_back(std::make_unique<UntilStatement>(Tok.file, Tok.line));
                }

                // --- .include / .inc ---
                else if (dir == ".include" || dir == ".inc") {
                    if (!TokIs(TokenKind::StringLiteral)) {
                        throw std::runtime_error(std::format(
                            "string filename after .include File: {} Line: {}",
                            src_mgr.GetFileName(Tok.file), Tok.line));
                    }

                    std::string inc_filename = Tok.text.substr(1, Tok.text.size() - 2);
                    ConsumeToken();

                    std::string filepath = inc_filename;
                    bool exists = fs::exists(filepath);

                    for (size_t index = 0; !exists && index < options.include.size(); ++index) {
                        filepath = options.include[index] + inc_filename;
                        exists = fs::exists(filepath);
                    }

                    if (!exists) {
                        throw std::runtime_error(std::format(
                            "unable to find .include '{}' File : {} Line: {}",
                            inc_filename, src_mgr.GetFileName(Tok.file), Tok.line));
                    }

                    auto inc_tokens = LoadAndTokenizeFile(filepath, src_mgr, tokenizer);
                    AssemblerParser parser(inc_tokens, options);
                    auto inc_statements = parser.ParseProgram(src_mgr, macros_, tokenizer);

                    for (auto& stmt : inc_statements) {
                        statements.push_back(std::move(stmt));
                    }

                    continue;
                }

                // --- .print ---
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

                // --- Conditional directives (.ifdef, .ifndef, .if, .else, .endif) ---
                else if (dir == ".ifdef" || dir == ".ifndef") {
                    if (!TokIs(TokenKind::Identifier)) {
                        throw std::runtime_error(std::format(
                            "Expected Identifier after {} File: {} Line: {}",
                            dir_tok.text, src_mgr.GetFileName(Tok.file), Tok.line
                        ));
                    }

                    auto sym = definedSyms.Lookup(Tok.text);
                    ConsumeToken();

                    bool is_true = (sym.has_value() && dir == ".ifdef") || (!sym.has_value() && dir == ".ifndef");

                    if (is_true) {
                        cond_stack.push_back({CondKind::IfDef, true});
                    } else {
                        SkipToElseOrEndif();
                        if (Tok.text == ".else") {
                            cond_stack.push_back({CondKind::IfDef, false});
                            ConsumeToken();
                        } else if (Tok.text == ".endif") {
                            ConsumeToken();
                        }
                    }
                }
                else if (dir == ".if") {
                    auto condition_expr = ParseExpression();
                    statements.push_back(std::make_unique<IfStatement>(dir_tok.file, dir_tok.line, condition_expr.move()));
                    cond_stack.push_back({CondKind::IfNode, true});
                }
                else if (dir == ".else") {
                    if (cond_stack.empty()) {
                        throw std::runtime_error(std::format("Unmatched .else at File: {} Line: {}", 
                            src_mgr.GetFileName(dir_tok.file), dir_tok.line));
                    }

                    if (cond_stack.back().kind == CondKind::IfNode) {
                        statements.push_back(std::make_unique<ElseStatement>(dir_tok.file, dir_tok.line));
                    } else {
                        bool if_was_true = cond_stack.back().if_was_true;
                        ConsumeToken();

                        if (if_was_true) {
                            SkipToElseOrEndif(); 
                            ConsumeToken();      
                            cond_stack.pop_back(); 
                        }
                    }
                }
                else if (dir == ".endif") {
                    if (cond_stack.empty()) {
                        throw std::runtime_error(std::format("Unmatched .endif at File: {} Line: {}", 
                            src_mgr.GetFileName(dir_tok.file), dir_tok.line));
                    }

                    if (cond_stack.back().kind == CondKind::IfNode) {
                        statements.push_back(std::make_unique<EndIfStatement>(dir_tok.file, dir_tok.line));
                    } else {
                        ConsumeToken();
                    }
                    
                    cond_stack.pop_back();
                }

                // --- .var ---
                else if (dir == ".var") {
                    std::vector<std::pair<std::string, std::unique_ptr<ExprNode>>> pairs;

                    do {
                        if (TokIs(TokenKind::Comma)) {
                            ConsumeToken();
                        }

                        if (TokIs(TokenKind::Identifier)) {
                            std::string sym_name = ConsumeToken().text;
                            std::unique_ptr<ExprNode> expr_node = nullptr;

                            if (TokIs(TokenKind::Equal)) {
                                ConsumeToken();
                                auto val_expr = ParseExpression();
                                
                                if (val_expr.isInvalid()) {
                                    throw std::runtime_error(
                                        std::format("Invalid expression for variable '{}' at line {}", sym_name, dir_tok.line));
                                }
                                
                                expr_node = val_expr.move();
                            } else {
                                expr_node = std::make_unique<NumberExpr>(0);
                            }

                            pairs.emplace_back(sym_name, std::move(expr_node));
                            definedSyms.Define(sym_name, 1);
                        } else {
                            throw std::runtime_error(
                                std::format("Expected variable identifier in .var directive at line {}", dir_tok.line));
                        }
                    } while (TokIs(TokenKind::Comma));

                    statements.push_back(std::make_unique<VarStatement>(dir_tok.file, dir_tok.line, std::move(pairs)));
                }

                // --- .error ---
                else if (dir == ".error") {
                    std::string msg = ".error encountred";
                    if (TokIs(TokenKind::StringLiteral)) {
                        msg = Tok.text;
                    }
                    throw std::runtime_error(msg);
                }

                else {
                    std::cout << "Warning Unknown directive '" << dir << "'  File: " << src_mgr.GetFileName(dir_tok.file) << " Line: " << dir_tok.line << "\n";
                }

                continue;
            }

            /**
             * @section Macro Expansion
             * Replaces macro invocation tokens with macro body tokens, performing positional 
             * parameter substitution (`\\1`, `\\2`) and local symbol mangling (`@`).
             */
            if (TokIs(TokenKind::Identifier) && IsMacro(Tok.text, macros_)) {
                // ... (Macro expansion continuation)
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

                    // prTok(src_mgr);

                    if (TokIs(TokenKind::Comma)) {
                        if (current_arg.size() == 1 && (current_arg[0].text == "+" || current_arg[0].text == "-")) {
                            throw std::runtime_error( std::format("Macros can not use anonomous labels {} File: {} Line: {}",
                                                  mac_call_tok.text, src_mgr.GetFileName(mac_call_tok.file), mac_call_tok.line));
                        }
                        args.push_back(current_arg);
                        current_arg.clear();
                        ConsumeToken();
                    } else {
                        auto tok = ConsumeToken();
                        current_arg.push_back(tok);
                    }
                }

                if (!current_arg.empty()) {
                    if (current_arg.size() == 1 && (current_arg[0].text == "+" || current_arg[0].text == "-")) {
                        throw std::runtime_error( std::format("Macros can not use anonomous labels {} File: {} Line: {}",
                                              mac_call_tok.text, src_mgr.GetFileName(mac_call_tok.file), mac_call_tok.line));
                    }
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
                                        a.file = mac_call_tok.file;
                                        a.line = mac_call_tok.line;
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
                            expTok.file = mac_call_tok.file;
                            expTok.line = mac_call_tok.line;
                            expTok.text = "@" + mac_call_tok.text + "_" + std::to_string(mac.times_called) + "_" + body_tok.text.substr(1);
                            expanded_tokens.push_back(expTok);
                            substituted = true;
                        }
                        else if ((body_tok.text[0] == '-' || (body_tok.text[0] == '+'))) {
                            throw std::runtime_error( std::format("Macros can not use anonomous labels {} File: {} Line: {}",
                                                          mac_call_tok.text, src_mgr.GetFileName(mac_call_tok.file), mac_call_tok.line));
                        }

                    }
                    if (!substituted) {
                        auto expTok = body_tok;
                        expTok.file = mac_call_tok.file;
                        expTok.line = mac_call_tok.line;
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

            /**
             * @section Instruction Parsing & Addressing Mode Resolution
             * Parses 6502 assembly opcodes and dispatches operand token sequences to their 
             * respective addressing modes:
             * - Implied / Accumulator (`NOP`, `LSR A`)
             * - Immediate (`#$FF`)
             * - Indirect Variants (`(expr,X)`, `(expr),Y`, `(expr)`)
             * - Absolute / Indexed (`expr`, `expr,X`, `expr,Y`)
             */
            if (TokIs(TokenKind::Opcode)) {

                PasmTokenizer::Token opcode_tok = ConsumeToken();
                std::string mnemonic = opcode_tok.text;
                RULE_TYPE mode = RULE_TYPE::Op_Implied;
                ExprResult operand_expr;

                // --- Immediate Addressing (#expr) ---
                if (TokIs(TokenKind::Hash)) {
                    ConsumeToken();
                    mode = RULE_TYPE::Op_Immediate;
                    operand_expr = ParseExpression();
                } 
                // --- Implied Addressing ---
                else if (TokIs(TokenKind::Newline) || TokIs(TokenKind::Eof) || TokIs(TokenKind::Semicolon)) {
                    mode = RULE_TYPE::Op_Implied;
                } 
                // --- Accumulator Addressing (e.g., ASL A, ROR A) ---
                else if (TokIs(TokenKind::Identifier) && (Tok.text == "a" || Tok.text == "A")) {
                    ConsumeToken();
                    mode = RULE_TYPE::Op_Accumulator;
                } 
                // --- Indirect Addressing Modes ---
                else if (TokIs(TokenKind::LParen)) {
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
                            // Standard Absolute Indirect: (expr) - e.g., JMP ($FFFC)
                            mode = RULE_TYPE::Op_Indirect;
                        }
                    } else {
                        throw std::runtime_error(std::format("Malformed indirect addressing mode File: {} Line {}", src_mgr.GetFileName(opcode_tok.file), opcode_tok.line));
                    }
                } 
                // --- Absolute, Absolute Indexed (X/Y), Zero-Page, or Relative ---
                else {
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
                        // Fall back to mnemonic-based deduction (e.g., relative branch vs absolute jump)
                        mode = DeduceMemoryMode(mnemonic);
                    }
                }

                statements.push_back(std::make_unique<InstructionStatement>(
                    opcode_tok.file, opcode_tok.line, mnemonic, mode, std::unique_ptr<ExprNode>(operand_expr.move())
                ));
                continue;
            }

            /**
             * @section Parsing Fallback & Recovery
             * Triggered when an unrecognized token sequence is encountered at statement start.
             * Logs a syntax error and advances the token stream to prevent infinite loops.
             */
            std::cout << "Syntax Error: Invalid token " << tokmap[static_cast<TokenKind>(Tok.id)] << " File: " << src_mgr.GetFileName(Tok.file) << " Line: " << Tok.line << "\n";
            ConsumeToken();
        }

        return statements;
    }

private:
    /**
     * @brief Parses binary expressions using Pratt precedence-climbing parsing.
     * 
     * Handles binary operators according to their precedence levels and associativity rules.
     * Continues parsing right-hand side expressions as long as incoming operators have a higher
     * precedence than @p min_prec.
     * 
     * @param min_prec The minimum operator precedence required to continue climbing.
     * @return ExprResult Containing the constructed binary AST subtree, or an error state.
     */
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
                                op_tok.id, lhs.move(), rhs.move()
                             ));
        }
        return lhs;
    }

    /**
     * @brief Parses primary expressions, literals, unary prefix operators, and parenthesized expressions.
     * 
     * Evaluates primary expression atoms:
     * - Numeric literals (Hex `$`, Binary `%`, Character `'a'`, Decimal)
     * - Single-character string literals
     * - Identifiers and program counter location counter (`*`)
     * - Anonymous relative labels (`+`, `-`, `++`, `--`, etc.)
     * - Sub-expressions enclosed in parentheses `(expr)`
     * - Unary prefix operations (`<`, `>`, `-`, `+`, `~`, `!`)
     * 
     * @return ExprResult The parsed leaf or unary AST node.
     */
    ExprResult ParsePrefixExpression() {
        // --- Numeric Literals ($1234, %10101010, 'A', 65535) ---
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
        
        // --- Single-Character String Literal as Byte Constant ---
        if (TokIs(TokenKind::StringLiteral) && (Tok.text.size() == 3)) {
            PasmTokenizer::Token t = ConsumeToken();
            auto val = static_cast<int64_t>(t.text[1]);
            return ExprResult(std::make_unique<NumberExpr>(val));
        }

        // --- Identifiers or Location Counter (*) ---
        if (TokIs(TokenKind::Identifier) || TokIs(TokenKind::Star)) {
            PasmTokenizer::Token t = ConsumeToken();
            return ExprResult(std::make_unique<SymbolExpr>(t.text));
        }

        // --- Anonymous Relative Labels (+, -, ++, --) ---
        auto anon_count = GetRelativeLabelCount();
        if (anon_count.has_value()) {
            auto forward = Tok.id == static_cast<int>(TokenKind::Plus);
            auto count = anon_count.value();
            for (auto i = 0; i < count; ++i) {
                ConsumeToken();
            }
            return ExprResult(std::make_unique<AnonLblExpr>(forward, count));
        }

        // --- Grouped Parenthesized Expression ---
        if (TokIs(TokenKind::LParen)) {
            ConsumeToken();
            ExprResult expr = ParseExpression(0);
            if (TokIs(TokenKind::RParen)) ConsumeToken();
            return expr;
        }

        // --- Unary Prefix Operators (<, >, -, +, ~, !) ---
        if (IsUnaryPrefix(Tok.id)) {
            PasmTokenizer::Token op_tok = ConsumeToken();
            ExprResult operand = ParseExpression(50);
            return ExprResult(std::make_unique<UnaryExpr>(op_tok.id, operand.move()));
        }

        return ExprResult::Error();
    }

    /**
     * @brief Retrieves precedence rank and associativity for binary operators.
     * 
     * Implements a standard operator hierarchy adapted for assembly expression logic, 
     * ranging from low-precedence logical OR (`||`) to high-precedence arithmetic (`*`, `/`, `%`).
     * 
     * @param kind Integer representation of the token kind (`TokenKind`).
     * @return OpPrecedence Struct containing numeric precedence value and operator associativity.
     */
    static OpPrecedence GetBinaryPrecedence(int kind) {
        switch ((TokenKind)kind) {
        case TokenKind::PipePipe:
            return { 5, Associativity::Left };
        case TokenKind::AmpersandAmpersand:
            return { 8, Associativity::Left };

        case TokenKind::Pipe:
            return { 10, Associativity::Left };
        case TokenKind::Caret:
            return { 15, Associativity::Left };
        case TokenKind::Ampersand:
            return { 20, Associativity::Left };

        case TokenKind::Equal:
        case TokenKind::EqualEqual:
        case TokenKind::NotEqual:
            return { 21, Associativity::Left };

        case TokenKind::Less:
        case TokenKind::LowByte:
        case TokenKind::LessEqual:
        case TokenKind::Greater:
        case TokenKind::HighByte:
        case TokenKind::GreaterEqual:
            return { 23, Associativity::Left };

        case TokenKind::Shl:
        case TokenKind::Shr:
            return { 25, Associativity::Left };
        case TokenKind::Plus:
        case TokenKind::Minus:
            return { 30, Associativity::Left };
        case TokenKind::Star:
        case TokenKind::Slash:
        case TokenKind::Percent:
            return { 40, Associativity::Left };
        default:
            return { -1, Associativity::Left };
        }
    }

    /**
     * @brief Checks if a token kind acts as a unary prefix operator.
     * 
     * Includes 6502-specific low-byte (`<`) and high-byte (`>`) extraction operators,
     * along with standard arithmetic/bitwise unary operators.
     * 
     * @param k Token ID to evaluate.
     * @return true If the token can precede a unary operand.
     * @return false Otherwise.
     */
    static bool IsUnaryPrefix(int k) {
        // Include BOTH LowByte/Less and HighByte/Greater here for prefix position
        return k == static_cast<int>(TokenKind::LowByte)  || k == static_cast<int>(TokenKind::Less)    ||
               k == static_cast<int>(TokenKind::HighByte) || k == static_cast<int>(TokenKind::Greater) ||
               k == static_cast<int>(TokenKind::Minus)    || k == static_cast<int>(TokenKind::Plus)    ||
               k == static_cast<int>(TokenKind::Tilde)    || k == static_cast<int>(TokenKind::Bang);
    }

    /**
     * @brief Deduces whether an opcode operand defaults to Relative or Absolute addressing.
     * 
     * Normalizes the mnemonic case and queries opcode metadata to determine if the 
     * operation uses relative branch offset addressing (e.g., `BNE`, `BEQ`) or falls 
     * back to absolute memory addressing.
     * 
     * @param mnemonic The instruction mnemonic string (e.g., "bne", "jmp").
     * @return RULE_TYPE Corresponding addressing mode (`Op_Relative` or `Op_Absolute`).
     */
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
