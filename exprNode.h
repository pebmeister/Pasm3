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

enum ExprType {
    UnknownExpr,
    Number,
    Symbol,
    AnonLbl,
    Unary,
    Binary
};

struct ExprNode {
    ExprType expr_type = ExprType::UnknownExpr;
    explicit ExprNode(ExprType expr_type) : expr_type(expr_type) {}
    virtual ~ExprNode() = default;

    // Pure virtual clone method
    virtual std::unique_ptr<ExprNode> clone() const = 0;
};

struct NumberExpr : ExprNode {
    int64_t value;
    explicit NumberExpr(int64_t val) : ExprNode(ExprType::Number), value(val) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<NumberExpr>(value);
    }
};

struct SymbolExpr : ExprNode {
    std::string name;
    explicit SymbolExpr(std::string n) : ExprNode(ExprType::Symbol), name(std::move(n)) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<SymbolExpr>(name);
    }
};

struct AnonLblExpr : ExprNode {
    bool forward;
    int count;
    explicit AnonLblExpr(bool f, int c) : ExprNode(ExprType::AnonLbl), forward(f), count(c) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<AnonLblExpr>(forward, count);
    }
};

struct UnaryExpr : ExprNode {
    int op;
    std::unique_ptr<ExprNode> operand;
    
    UnaryExpr(int op, std::unique_ptr<ExprNode> rhs)
        : ExprNode(ExprType::Unary), op(op), operand(std::move(rhs)) {}

    std::unique_ptr<ExprNode> clone() const override {
        return std::make_unique<UnaryExpr>(op, operand ? operand->clone() : nullptr);
    }
};

struct BinaryExpr : ExprNode {
    int op;
    std::unique_ptr<ExprNode> lhs;
    std::unique_ptr<ExprNode> rhs;
    
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
    std::unique_ptr<ExprNode> move() {
        return std::move(node_);
    }
};

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
