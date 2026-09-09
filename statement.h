#pragma once 

#include <memory>
#include <string>
#include <vector>
#include <utility>

enum StmtType {
    Label,
    Org,
    Equ,
    Ds,
    Data,
    Fill,
    Instruction,
    Print,
    While,
    Wend,
    Unknown
};

enum PrintCmd {
    on,
    off,
    push,
    pop
};

#include "exprNode.h"

// Helper function to safely clone an ExprNode unique_ptr
inline std::unique_ptr<ExprNode> CloneExpr(const std::unique_ptr<ExprNode>& expr) {
    return expr ? expr->clone() : nullptr;
}

// ============================================================================
// 3. Intermediate Representation (IR) Statements
// ============================================================================

struct Statement {
    virtual ~Statement() = default;

    int file{0};
    int line{0};
    StmtType stmt_type{StmtType::Unknown};

    Statement(int file, int line, StmtType stmt_type)
        : file(file), line(line), stmt_type(stmt_type) {}

    // Pure virtual deep-copy method
    virtual std::unique_ptr<Statement> clone() const = 0;
};

struct LabelStatement : Statement {
    std::string name;

    bool is_local() const { return name[0] == '@'; }
    bool is_anon() const { return name[0] == '-' || name[0] == '+'; }

    explicit LabelStatement(int file, int line, std::string name)
        : Statement(file, line, StmtType::Label), name(std::move(name)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<LabelStatement>(file, line, name);
    }
};

struct InstructionStatement : Statement {
    uint16_t address{0};
    std::string mnemonic;
    RULE_TYPE mode{RULE_TYPE::Op_Implied};
    std::unique_ptr<ExprNode> operand{nullptr};
    std::vector<uint8_t> bytes;

    InstructionStatement(int file, int line, std::string m, RULE_TYPE mode, std::unique_ptr<ExprNode> op)
        : Statement(file, line, StmtType::Instruction), mnemonic(std::move(m)), mode(mode), operand(std::move(op)) {}

    std::unique_ptr<Statement> clone() const override {
        auto inst = std::make_unique<InstructionStatement>(file, line, mnemonic, mode, CloneExpr(operand));
        inst->address = address;
        inst->bytes = bytes;
        return inst;
    }
};

struct OrgStatement : Statement {
    std::unique_ptr<ExprNode> address_expr;

    explicit OrgStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Org), address_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<OrgStatement>(file, line, CloneExpr(address_expr));
    }
};

struct FillStatement : Statement {
    std::unique_ptr<ExprNode> byte_expr;
    std::unique_ptr<ExprNode> length_expr;

    explicit FillStatement(int file, int line, std::unique_ptr<ExprNode> byteexpr, std::unique_ptr<ExprNode> lenexpr)
        : Statement(file, line, StmtType::Fill), byte_expr(std::move(byteexpr)), length_expr(std::move(lenexpr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<FillStatement>(file, line, CloneExpr(byte_expr), CloneExpr(length_expr));
    }
};

struct DsStatement : Statement {
    std::unique_ptr<ExprNode> size_expr;

    explicit DsStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Ds), size_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<DsStatement>(file, line, CloneExpr(size_expr));
    }
};

struct EquStatement : Statement {
    std::string name;
    bool is_local() const { return name[0] == '@'; }

    std::unique_ptr<ExprNode> value_expr;

    EquStatement(int file, int line, std::string n, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Equ), name(std::move(n)), value_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<EquStatement>(file, line, name, CloneExpr(value_expr));
    }
};

enum class DataWidth { Byte, Word };

struct DataStatement : Statement {
    DataWidth width{DataWidth::Byte};
    std::vector<std::unique_ptr<ExprNode>> elements;

    DataStatement(int file, int line, DataWidth w, std::vector<std::unique_ptr<ExprNode>> elems)
        : Statement(file, line, StmtType::Data), width(w), elements(std::move(elems)) {}

    std::unique_ptr<Statement> clone() const override {
        std::vector<std::unique_ptr<ExprNode>> cloned_elems;
        cloned_elems.reserve(elements.size());
        for (const auto& elem : elements) {
            cloned_elems.push_back(CloneExpr(elem));
        }
        return std::make_unique<DataStatement>(file, line, width, std::move(cloned_elems));
    }
};

struct PrintStatement : Statement {
    PrintCmd cmd;

    explicit PrintStatement(int file, int line, PrintCmd cmd)
        : Statement(file, line, StmtType::Print), cmd(cmd) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<PrintStatement>(file, line, cmd);
    }
};

struct WhileStatement : Statement {
    std::unique_ptr<ExprNode> condition_expr;
    std::vector<std::unique_ptr<Statement>> statements;

    explicit WhileStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::While), condition_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        auto cloned_while = std::make_unique<WhileStatement>(file, line, CloneExpr(condition_expr));
        cloned_while->statements.reserve(statements.size());
        for (const auto& stmt : statements) {
            if (stmt) {
                cloned_while->statements.push_back(stmt->clone());
            }
        }
        return cloned_while;
    }
};

struct WendStatement : Statement {
    explicit WendStatement(int file, int line)
        : Statement(file, line, StmtType::Wend) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<WendStatement>(file, line);
    }
};
