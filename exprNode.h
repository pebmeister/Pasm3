#pragma once

#include <memory>
#include <string>
#include <vector>
#include <optional>
#include <utility>
#include <cstdint>

#include "tokenkind.h"
#include "getmangledsymbol.h"
#include "findanonlabel.h"
#include "symboltable.h"

/**
 * @file exprNode.h
 * @author Paul Baxter
 */


/**
 * @enum ExprType
 * @brief Discriminator tags for expression AST node types.
 */
enum ExprType {
    UnknownExpr, /**< Uninitialized or unrecognized expression node. */
    Number,      /**< Numeric integer literal node. */
    Symbol,      /**< Identifier or symbol reference node. */
    AnonLbl,     /**< Anonymous label reference node (e.g., +, -). */
    Unary,       /**< Unary prefix operation node. */
    Binary       /**< Binary infix operation node. */
};

/**
 * @struct ExprNode
 * @brief Abstract base class for all nodes in the expression Abstract Syntax Tree (AST).
 */
struct ExprNode {
    ExprType expr_type = ExprType::UnknownExpr; /**< Category tag identifying the node sub-type. */

    /**
     * @brief Constructs an ExprNode with a specific type discriminator.
     * @param expr_type Specific expression type tag.
     */
    explicit ExprNode(ExprType expr_type) : expr_type(expr_type) {}

    /**
     * @brief Virtual destructor for polymorphic cleanup.
     */
    virtual ~ExprNode() = default;

    /**
     * @brief Creates a deep copy clone of the expression AST node.
     * @return std::unique_ptr<ExprNode> Deep-copied instance of the node tree.
     */
    virtual std::unique_ptr<ExprNode> clone() const = 0;
};

/**
 * @struct NumberExpr
 * @brief AST node representing a 64-bit integer literal value.
 */
struct NumberExpr : ExprNode {
    int64_t value; /**< Evaluated numeric literal value. */

    /**
     * @brief Constructs a NumberExpr node.
     * @param val 64-bit integer literal value.
     */
    explicit NumberExpr(int64_t val) : ExprNode(ExprType::Number), value(val) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<NumberExpr>(value);
    }
};

/**
 * @struct SymbolExpr
 * @brief AST node representing a named symbol, local label, or program counter location counter.
 */
struct SymbolExpr : ExprNode {
    std::string name; /**< Identifier string (e.g., "LABEL", "@local", "*"). */

    /**
     * @brief Constructs a SymbolExpr node.
     * @param n Symbol identifier string name.
     */
    explicit SymbolExpr(std::string n) : ExprNode(ExprType::Symbol), name(std::move(n)) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<SymbolExpr>(name);
    }
};

/**
 * @struct AnonLblExpr
 * @brief AST node representing an anonymous relative label reference (e.g., +++, --).
 */
struct AnonLblExpr : ExprNode {
    bool forward; /**< True for forward references (+), false for backward references (-). */
    int count;    /**< Ordinal offset count of the anonymous label reference. */

    /**
     * @brief Constructs an AnonLblExpr node.
     * @param f Reference direction (true = forward, false = backward).
     * @param c Ordinal count of relative target label.
     */
    explicit AnonLblExpr(bool f, int c) : ExprNode(ExprType::AnonLbl), forward(f), count(c) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<AnonLblExpr>(forward, count);
    }
};

/**
 * @struct UnaryExpr
 * @brief AST node representing a unary prefix operator expression.
 */
struct UnaryExpr : ExprNode {
    int op;                             /**< Operator identifier (castable to TokenKind). */
    std::unique_ptr<ExprNode> operand;  /**< Smart pointer to operand subtree. */

    /**
     * @brief Constructs a UnaryExpr node.
     * @param op Unary operator token ID.
     * @param rhs Smart pointer to the right-hand operand expression AST node.
     */
    UnaryExpr(int op, std::unique_ptr<ExprNode> rhs)
        : ExprNode(ExprType::Unary), op(op), operand(std::move(rhs)) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<UnaryExpr>(op, operand ? operand->clone() : nullptr);
    }
};

/**
 * @struct BinaryExpr
 * @brief AST node representing a binary infix operator expression.
 */
struct BinaryExpr : ExprNode {
    int op;                           /**< Operator identifier (castable to TokenKind). */
    std::unique_ptr<ExprNode> lhs;    /**< Smart pointer to left-hand operand subtree. */
    std::unique_ptr<ExprNode> rhs;    /**< Smart pointer to right-hand operand subtree. */

    /**
     * @brief Constructs a BinaryExpr node.
     * @param op Binary operator token ID.
     * @param l Smart pointer to left-hand operand expression AST node.
     * @param r Smart pointer to right-hand operand expression AST node.
     */
    BinaryExpr(int op, std::unique_ptr<ExprNode> l, std::unique_ptr<ExprNode> r)
        : ExprNode(ExprType::Binary), op(op), lhs(std::move(l)), rhs(std::move(r)) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<BinaryExpr>(
            op, 
            lhs ? lhs->clone() : nullptr, 
            rhs ? rhs->clone() : nullptr
        );
    }
};

/**
 * @class ExprResult
 * @brief Monadic-style wrapper holding either a successfully parsed ExprNode AST or an error state.
 */
class ExprResult {
    std::unique_ptr<ExprNode> node_{nullptr}; /**< Root AST node pointer. */
    bool invalid_{false};                      /**< Flag indicating parse/syntax error state. */

public:
    /**
     * @brief Default constructor creating an empty, non-error result.
     */
    ExprResult() = default;

    /**
     * @brief Constructs a successful result with an AST node.
     * @param node Smart pointer to parsed root ExprNode.
     */
    ExprResult(std::unique_ptr<ExprNode> node) : node_(std::move(node)) {}

    /**
     * @brief Static factory method creating an explicit error expression result.
     * @return ExprResult Object marked as invalid/error.
     */
    static ExprResult Error() {
        ExprResult res;
        res.invalid_ = true;
        return res;
    }

    /**
     * @brief Checks if the result represents an invalid expression or parse error.
     * @return True if invalid/error, false otherwise.
     */
    [[nodiscard]] bool isInvalid() const {
        return invalid_;
    }

    /**
     * @brief Checks if the result holds a valid, usable expression node.
     * @return True if valid and holding a non-null node.
     */
    [[nodiscard]] bool isUsable() const {
        return !invalid_ && node_ != nullptr;
    }

    /**
     * @brief Gets a raw pointer to the contained AST node.
     * @return Constant pointer to ExprNode, or nullptr if empty.
     */
    const ExprNode* get() const {
        return node_.get();
    }

    /**
     * @brief Transfers ownership of the contained AST node.
     * @return std::unique_ptr<ExprNode> Smart pointer to expression node.
     */
    std::unique_ptr<ExprNode> move() {
        return std::move(node_);
    }
};

/**
 * @brief Recursively evaluates an expression AST node to a 64-bit integer value.
 * 
 * Resolves literals, symbol lookups (including variable dynamic state, local label mangling,
 * and PC counter '*'), anonymous relative labels, unary byte/bitwise operations, and 
 * binary arithmetic/bitwise/logical operators.
 * 
 * @param node Pointer to the root AST node to evaluate.
 * @param anonymous_labels Vector of recorded anonymous labels in source file.
 * @param symbols Symbol table containing constants and code address labels.
 * @param vars Symbol table containing dynamic assembler variables (.var).
 * @param parent_scope Name of the current global label scope for local (@) mangling.
 * @param pc Current program counter memory address value.
 * @return std::optional<int64_t> Evaluated result value, or std::nullopt if resolution fails.
 */
inline std::optional<int64_t> EvaluateExpr(const ExprNode* node, const std::vector<AnonymousLabel>& anonymous_labels, 
    const SymbolTable& symbols, const SymbolTable& vars, const std::string& parent_scope, uint16_t pc ) {
    if (!node) return std::nullopt;

    auto node_type = node->expr_type;
    
    switch (node_type) {
        case ExprType::Number: {
            auto num = static_cast<const NumberExpr*>(node);
            return num->value;
        }

        case ExprType::Symbol: {
            auto sym = static_cast<const SymbolExpr*>(node);
            auto name = sym->name;

            auto val = vars.Lookup(name);
            if (val.has_value()) return static_cast<int64_t>(val.value());

            if (sym->name[0] == '@') {
                name = GetMangledSymbol(name, parent_scope);
            }
            else if (sym->name[0] == '*') {
                return pc;
            }
            val = symbols.Lookup(name);
            if (val.has_value()) return static_cast<int64_t>(val.value());
            return std::nullopt;
        }

        case ExprType::AnonLbl: {
            auto anon = static_cast<const AnonLblExpr*>(node);
            return FindAnonLabel(anonymous_labels, anon->forward, anon->count, pc);
        }

        case ExprType::Unary: {
            auto un = dynamic_cast<const UnaryExpr*>(node);

            if (!un->operand) return std::nullopt;
            auto val = EvaluateExpr(un->operand.get(), anonymous_labels, symbols, vars, parent_scope, pc);
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
        

        case ExprType::Binary: {
            auto bin = dynamic_cast<const BinaryExpr*>(node);
            if (!bin->lhs || !bin->rhs) return std::nullopt;

            auto lhs = EvaluateExpr(bin->lhs.get(), anonymous_labels, symbols, vars, parent_scope, pc);
            auto rhs = EvaluateExpr(bin->rhs.get(), anonymous_labels, symbols, vars, parent_scope, pc);
            if (!lhs || !rhs) return std::nullopt;

            switch ((TokenKind)bin->op) {
                // --- Logical Operators ---
                case TokenKind::AmpersandAmpersand:
                    return (*lhs != 0 && *rhs != 0) ? 1 : 0;
                case TokenKind::PipePipe:
                    return (*lhs != 0 || *rhs != 0) ? 1 : 0;

                // --- Comparative Operators ---
                case TokenKind::Less:
                case TokenKind::LowByte:
                    return (*lhs < *rhs) ? 1 : 0;
                case TokenKind::Greater:
                case TokenKind::HighByte:
                    return (*lhs > *rhs) ? 1 : 0;
                case TokenKind::LessEqual:    return (*lhs <= *rhs) ? 1 : 0;
                case TokenKind::GreaterEqual: return (*lhs >= *rhs) ? 1 : 0;
                case TokenKind::EqualEqual:
                case TokenKind::Equal:        return (*lhs == *rhs) ? 1 : 0;
                case TokenKind::NotEqual:     return (*lhs != *rhs) ? 1 : 0;

                // --- Bitwise & Arithmetic ---
                case TokenKind::Ampersand:    return *lhs & *rhs;
                case TokenKind::Pipe:         return *lhs | *rhs;
                case TokenKind::Caret:        return *lhs ^ *rhs;
                case TokenKind::Plus:         return *lhs + *rhs;
                case TokenKind::Minus:        return *lhs - *rhs;
                case TokenKind::Star:         return *lhs * *rhs;
                case TokenKind::Slash:        return (*rhs != 0) ? *lhs / *rhs : 0;
                case TokenKind::Percent:      return (*rhs != 0) ? *lhs % *rhs : 0;
                case TokenKind::Shl:          return *lhs << *rhs;
                case TokenKind::Shr:          return *lhs >> *rhs;

                default:
                    return std::nullopt;
            }
        }


        case ExprType::UnknownExpr:
            return std::nullopt;
    }
    return std::nullopt;
}