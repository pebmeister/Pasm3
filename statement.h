#pragma once 

enum class StmtType {
    Label,
    Org,
    Equ,
    Ds,
    Data,
    Fill,
    Instruction,
    Print,
    Unknown
};

enum PrintCmd {
	on,
	off,
	push,
	pop
};

#include "exprNode.h"

// ============================================================================
// 3. Intermediate Representation (IR) Statements
// ============================================================================

struct Statement {
    virtual ~Statement() = default;
|
    int file{0};
    int line{0};
    StmtType stmt_type{StmtType::Unknown};

    Statement(int file, int line, StmtType stmt_type)
        : file(file), line(line), stmt_type(stmt_type)
};

struct LabelStatement : Statement {
    std::string name;
	bool is_local() const { return name[0] == '@'; }
	bool is_anon() const { return name[0] == '-' || name[0] == '+'; }
    explicit LabelStatement(int file, int line, std::string name) : Statement(file, line, StmtType::Label), name(std::move(name)) {}
};

struct InstructionStatement : Statement {
    uint16_t address{0};
    std::string mnemonic;
    RULE_TYPE mode{RULE_TYPE::Op_Implied};
    std::unique_ptr<ExprNode> operand{nullptr};
    std::vector<uint8_t> bytes;

    InstructionStatement(int file, int line, std::string m, RULE_TYPE mode, std::unique_ptr<ExprNode> op)
        : Statement(file, line, StmtType::Instruction), mnemonic(std::move(m)), mode(mode), operand(std::move(op)) {}
};

struct OrgStatement : Statement {
    std::unique_ptr<ExprNode> address_expr;
    explicit OrgStatement(int file, int line, std::unique_ptr<ExprNode> expr) : Statement(file, line, StmtType::Org), address_expr(std::move(expr)) {}
};

struct FillStatement : Statement {
    std::unique_ptr<ExprNode> byte_expr;
    std::unique_ptr<ExprNode> length_expr;
    explicit FillStatement(int file, int line, std::unique_ptr<ExprNode> byteexpr, std::unique_ptr<ExprNode> lenexpr) : Statement(file, line, StmtType::Fill),
        byte_expr(std::move(byteexpr)), length_expr(std::move(lenexpr)) {}
};

struct DsStatement : Statement {
    std::unique_ptr<ExprNode> size_expr;
    explicit DsStatement(int file, int line, std::unique_ptr<ExprNode> expr) : Statement(file, line, StmtType::Ds), size_expr(std::move(expr)) {}
};

struct EquStatement : Statement {
    std::string name;
	bool is_local() const { return name[0] == '@'; }

    std::unique_ptr<ExprNode> value_expr;
    EquStatement(int file, int line, std::string n, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Equ), name(std::move(n)), value_expr(std::move(expr)) {}
};

enum class DataWidth { Byte, Word };

struct DataStatement : Statement {
    DataWidth width{DataWidth::Byte};
    std::vector<std::unique_ptr<ExprNode>> elements;

    DataStatement(int file, int line, DataWidth w, std::vector<std::unique_ptr<ExprNode>> elems)
        : Statement(file, line, StmtType::Data), width(w), elements(std::move(elems)) {}
};

struct PrintStatement : Statement {
    PrintCmd cmd;
    explicit PrintStatement(int file, int line, PrintCmd cmd) : Statement(file, line, StmtType::Print), cmd(std::move(cmd)) {}
};