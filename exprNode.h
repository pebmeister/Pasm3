#pragma once

#include "tokenkind.h"
#include "getmangledsymbol.h"
#include "findanonlabel.h"

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

struct AnonLblExpr : ExprNode {
    bool forward;
    int count;
    explicit AnonLblExpr(bool f, int c) : forward(f), count(c) {}
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

inline std::optional<int64_t> EvaluateExpr(const ExprNode* node, const std::vector<AnonymousLabel>& anonymous_labels, const SymbolTable& symbols,
        const std::string& parent_scope, uint16_t pc ) {
    if (!node) return std::nullopt;

    if (auto num = dynamic_cast<const NumberExpr*>(node)) return num->value;

    if (auto sym = dynamic_cast<const SymbolExpr*>(node)) {
        auto name = sym->name;
        if (sym->name[0] == '@') {
            name = GetMangledSymbol(name, parent_scope);
        }
        else if (sym->name[0] == '*') {
            return pc;
        }
        auto val = symbols.Lookup(name);
        if (val.has_value()) return static_cast<int64_t>(val.value());
        return std::nullopt;
    }

    if (auto anon = dynamic_cast<const AnonLblExpr*>(node)) {
        return FindAnonLabel(anonymous_labels, anon->forward, anon->count, pc);
    }

    if (auto un = dynamic_cast<const UnaryExpr*>(node)) {

        if (!un->operand) return std::nullopt;
        auto val = EvaluateExpr(un->operand.get(), anonymous_labels, symbols, parent_scope, pc);
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
        auto lhs = EvaluateExpr(bin->lhs.get(), anonymous_labels, symbols, parent_scope, pc);
        auto rhs = EvaluateExpr(bin->rhs.get(), anonymous_labels, symbols, parent_scope, pc);
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


