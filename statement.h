#pragma once 

#include <memory>
#include <string>
#include <vector>
#include <utility>

/**
 * @enum StmtType
 * @brief Defines the categories for Intermediate Representation (IR) statements.
 * @author Paul Baxter
 */
enum StmtType {
    Label,       /**< Label definition. */
    Org,         /**< Origin location directive (.org). */
    Equ,         /**< Equate symbol directive (.equ). */
    Ds,          /**< Define storage/reservation directive (.ds). */
    Data,        /**< Raw data directive (.byte, .word). */
    Fill,        /**< Memory fill directive (.fill). */
    Instruction, /**< CPU machine instruction. */
    Print,       /**< Assembly listing output control directive. */
    While,       /**< While loop start marker. */
    Wend,        /**< While loop end marker. */
    Repeat,      /**< Repeat loop start marker. */
    Until,       /**< Until condition check marker. */
    Loop,        /**< Compound structured loop construct block. */
    Var,         /**< Variable declaration directive (.var). */
    If,          /**< Conditional construct block. */
    Else,        /**< Else branch marker. */
    EndIf,       /**< Conditional construct end marker. */
    Break,       /**< Loop control break statement. */
    Continue,    /**< Loop control continue statement. */
    Unknown      /**< Unrecognized or uninitialized statement type. */
};

/**
 * @enum PrintCmd
 * @brief Defines commands for controlling assembler output listing generation.
 */
enum PrintCmd {
    on,   /**< Enable listing output. */
    off,  /**< Disable listing output. */
    push, /**< Save current listing state to stack. */
    pop   /**< Restore previous listing state from stack. */
};

#include "exprNode.h"

/**
 * @brief Safely clones an ExprNode held within a unique_ptr.
 * @param expr Smart pointer reference to the expression AST node to duplicate.
 * @return std::unique_ptr<ExprNode> Deep clone of the expression tree, or nullptr if the input is null.
 */
inline std::unique_ptr<ExprNode> CloneExpr(const std::unique_ptr<ExprNode>& expr) {
    return expr ? expr->clone() : nullptr;
}

// ============================================================================
// 3. Intermediate Representation (IR) Statements
// ============================================================================

/**
 * @struct Statement
 * @brief Base AST/IR node representing a single statement in source assembly.
 */
struct Statement {
    virtual ~Statement() = default;

    int file{0};               /**< Source file index/ID where this statement originated. */
    int line{0};               /**< Line number within the source file. */
    StmtType stmt_type{StmtType::Unknown}; /**< Specific statement type classification. */

    /**
     * @brief Constructs a new base Statement object.
     * @param file Source file identifier.
     * @param line Source line index.
     * @param stmt_type Category tag for this statement.
     */
    Statement(int file, int line, StmtType stmt_type)
        : file(file), line(line), stmt_type(stmt_type) {}

    /**
     * @brief Creates a deep copy clone of the statement node.
     * @return std::unique_ptr<Statement> Cloned statement object.
     */
    virtual std::unique_ptr<Statement> clone() const = 0;
};

/**
 * @struct LabelStatement
 * @brief Represents a label identifier in assembly code.
 */
struct LabelStatement : Statement {
    std::string name; /**< Identifier name of the declared label. */

    /**
     * @brief Checks if the symbol is a scope-local label (starts with '@').
     * @return True if local symbol, false otherwise.
     */
    bool is_local() const { return !name.empty() && name[0] == '@'; }

    /**
     * @brief Checks if the symbol is an anonymous label (starts with '+' or '-').
     * @return True if anonymous symbol, false otherwise.
     */
    bool is_anon() const { return !name.empty() && (name[0] == '-' || name[0] == '+'); }

    /**
     * @brief Constructs a LabelStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param name Name of the label symbol.
     */
    explicit LabelStatement(int file, int line, std::string name)
        : Statement(file, line, StmtType::Label), name(std::move(name)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<LabelStatement>(file, line, name);
    }
};

/**
 * @struct InstructionStatement
 * @brief Represents a target architecture CPU instruction statement.
 */
struct InstructionStatement : Statement {
    uint16_t address{0};           /**< Assembled target memory address. */
    std::string mnemonic;          /**< Opcode mnemonic string (e.g. "lda", "sta"). */
    RULE_TYPE mode{RULE_TYPE::Op_Implied}; /**< Target addressing mode category. */
    std::unique_ptr<ExprNode> operand{nullptr}; /**< Expression tree for instruction operand, if present. */
    std::vector<uint8_t> bytes;    /**< Generated binary machine code byte sequence. */

    /**
     * @brief Constructs an InstructionStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param m Mnemonic string.
     * @param mode Addressing mode identifier.
     * @param op Operand expression AST node smart pointer.
     */
    InstructionStatement(int file, int line, std::string m, RULE_TYPE mode, std::unique_ptr<ExprNode> op)
        : Statement(file, line, StmtType::Instruction), mnemonic(std::move(m)), mode(mode), operand(std::move(op)) {}

    std::unique_ptr<Statement> clone() const override {
        auto inst = std::make_unique<InstructionStatement>(file, line, mnemonic, mode, CloneExpr(operand));
        inst->address = address;
        inst->bytes = bytes;
        return inst;
    }
};

/**
 * @struct OrgStatement
 * @brief Represents an origin location counter directive (.org).
 */
struct OrgStatement : Statement {
    std::unique_ptr<ExprNode> address_expr; /**< Expression defining target start address. */

    /**
     * @brief Constructs an OrgStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param expr Origin target memory address expression tree.
     */
    explicit OrgStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Org), address_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<OrgStatement>(file, line, CloneExpr(address_expr));
    }
};

/**
 * @struct FillStatement
 * @brief Represents a memory block fill directive (.fill).
 */
struct FillStatement : Statement {
    std::unique_ptr<ExprNode> byte_expr;   /**< Expression yielding byte value pattern to fill. */
    std::unique_ptr<ExprNode> length_expr; /**< Expression yielding total byte count to allocate. */

    /**
     * @brief Constructs a FillStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param byteexpr Fill value expression AST node.
     * @param lenexpr Fill length expression AST node.
     */
    explicit FillStatement(int file, int line, std::unique_ptr<ExprNode> byteexpr, std::unique_ptr<ExprNode> lenexpr)
        : Statement(file, line, StmtType::Fill), byte_expr(std::move(byteexpr)), length_expr(std::move(lenexpr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<FillStatement>(file, line, CloneExpr(byte_expr), CloneExpr(length_expr));
    }
};

/**
 * @struct DsStatement
 * @brief Represents a storage reservation directive (.ds).
 */
struct DsStatement : Statement {
    std::unique_ptr<ExprNode> size_expr; /**< Expression evaluating size in bytes to reserve. */

    /**
     * @brief Constructs a DsStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param expr Reservation size expression AST node.
     */
    explicit DsStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Ds), size_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<DsStatement>(file, line, CloneExpr(size_expr));
    }
};

/**
 * @struct EquStatement
 * @brief Represents a symbol constant equate assignment (.equ).
 */
struct EquStatement : Statement {
    std::string name;                     /**< Target constant symbol identifier string. */
    std::unique_ptr<ExprNode> value_expr; /**< Value expression assigned to the symbol. */

    /**
     * @brief Checks if the equate symbol is local (starts with '@').
     * @return True if local symbol, false otherwise.
     */
    bool is_local() const { return !name.empty() && name[0] == '@'; }

    /**
     * @brief Constructs an EquStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param n Symbol identifier string.
     * @param expr Evaluated value expression tree.
     */
    EquStatement(int file, int line, std::string n, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::Equ), name(std::move(n)), value_expr(std::move(expr)) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<EquStatement>(file, line, name, CloneExpr(value_expr));
    }
};

/**
 * @struct VarStatement
 * @brief Represents variable declaration statements (.var).
 */
struct VarStatement : Statement {
    std::vector<std::pair<std::string, std::unique_ptr<ExprNode>>> vars; /**< Variable identifier and initializer pairs. */

    /**
     * @brief Constructs a VarStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param vars List of variable name and initial expression value pairs.
     */
    VarStatement(int file, int line, std::vector<std::pair<std::string, std::unique_ptr<ExprNode>>> vars)
        : Statement(file, line, StmtType::Var), vars(std::move(vars)) {}

    std::unique_ptr<Statement> clone() const override {
        std::vector<std::pair<std::string, std::unique_ptr<ExprNode>>> cloned_vars;
        cloned_vars.reserve(vars.size());

        for (const auto& [name, expr] : vars) {
            cloned_vars.emplace_back(
                name,
                expr ? expr->clone() : nullptr
            );
        }

        return std::make_unique<VarStatement>(file, line, std::move(cloned_vars));
    }
};

/**
 * @enum class DataWidth
 * @brief Specifies element width for raw data directives.
 */
enum class DataWidth {
    Byte, /**< 8-bit byte elements (.byte). */
    Word  /**< 16-bit word elements (.word). */
};

/**
 * @struct DataStatement
 * @brief Represents raw data table directives (.byte, .word).
 */
struct DataStatement : Statement {
    DataWidth width{DataWidth::Byte};                 /**< Bit width per data element. */
    std::vector<std::unique_ptr<ExprNode>> elements; /**< List of evaluated element expression trees. */

    /**
     * @brief Constructs a DataStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param w Data size width specification (Byte or Word).
     * @param elems Expressions evaluating to individual data elements.
     */
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

/**
 * @struct PrintStatement
 * @brief Represents assembly listing printing control directives (.print).
 */
struct PrintStatement : Statement {
    PrintCmd cmd; /**< Listing control command action. */

    /**
     * @brief Constructs a PrintStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param cmd Listing directive command.
     */
    explicit PrintStatement(int file, int line, PrintCmd cmd)
        : Statement(file, line, StmtType::Print), cmd(cmd) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<PrintStatement>(file, line, cmd);
    }
};

/**
 * @struct LoopStatement
 * @brief Represents structured control-flow loop blocks (while/wend, repeat/until).
 */
struct LoopStatement : Statement {
    std::unique_ptr<ExprNode> condition_expr;          /**< Condition expression controlling loop iteration. */
    std::vector<std::unique_ptr<Statement>> statements; /**< Statements forming the inner body of the loop. */
    
    StmtType loop_start_keyword; /**< Opening keyword directive (While / Repeat). */
    StmtType loop_end_keyword;   /**< Closing keyword directive (Wend / Until). */
    bool test_at_top;            /**< True if condition is evaluated before loop body execution. */
    bool reverse_logic;          /**< True if loop terminates when expression yields true (until). */

    /**
     * @brief Constructs a LoopStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param expr Loop evaluation expression AST node.
     * @param start_kw Enum identifying opening loop directive keyword.
     * @param end_kw Enum identifying closing loop directive keyword.
     * @param test_top Flag indicating top-of-loop testing logic.
     * @param rev_logic Flag indicating inverted truth evaluation.
     */
    explicit LoopStatement(int file, int line, std::unique_ptr<ExprNode> expr, 
                           StmtType start_kw, StmtType end_kw, bool test_top, bool rev_logic)
        : Statement(file, line, StmtType::Loop), 
          condition_expr(std::move(expr)),
          loop_start_keyword(start_kw),
          loop_end_keyword(end_kw),
          test_at_top(test_top),
          reverse_logic(rev_logic) {}

    std::unique_ptr<Statement> clone() const override {
        auto cloned_loop = std::make_unique<LoopStatement>(
            file, line, CloneExpr(condition_expr), loop_start_keyword, loop_end_keyword, test_at_top, reverse_logic);
        
        cloned_loop->statements.reserve(statements.size());
        for (const auto& stmt : statements) {
            if (stmt) {
                cloned_loop->statements.push_back(stmt->clone());
            }
        }
        return cloned_loop;
    }
};

/**
 * @struct WendStatement
 * @brief Represents the end marker for a while loop block.
 */
struct WendStatement : Statement {
    /**
     * @brief Constructs a WendStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit WendStatement(int file, int line)
        : Statement(file, line, StmtType::Wend) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<WendStatement>(file, line);
    }
};

/**
 * @struct IfStatement
 * @brief Represents structured conditional execution branching (if-then-else).
 */
struct IfStatement : Statement {
    std::unique_ptr<ExprNode> condition_expr;             /**< Branching evaluation expression tree. */
    std::vector<std::unique_ptr<Statement>> then_statements; /**< Body statements executed when condition evaluates non-zero. */
    std::vector<std::unique_ptr<Statement>> else_statements; /**< Body statements executed when condition evaluates zero. */

    /**
     * @brief Constructs an IfStatement node.
     * @param file Source file index.
     * @param line Source line index.
     * @param expr Branch condition expression AST node.
     */
    explicit IfStatement(int file, int line, std::unique_ptr<ExprNode> expr)
        : Statement(file, line, StmtType::If), condition_expr(std::move(expr))  {}

    std::unique_ptr<Statement> clone() const override {
        auto if_clone = std::make_unique<IfStatement>(file, line, CloneExpr(condition_expr));
        for (const auto& stmt : then_statements) {
            if (stmt) {
                if_clone->then_statements.push_back(stmt->clone());
            }
        }
        for (const auto& stmt : else_statements) {
            if (stmt) {
                if_clone->else_statements.push_back(stmt->clone());
            }
        }
        return if_clone;
    }
};

/**
 * @struct ElseStatement
 * @brief Represents the else branch marker statement in a conditional block.
 */
struct ElseStatement : Statement {
    /**
     * @brief Constructs an ElseStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit ElseStatement(int file, int line)
        : Statement(file, line, StmtType::Else) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<ElseStatement>(file, line);
    }
};

/**
 * @struct EndIfStatement
 * @brief Represents the closing statement for a conditional block.
 */
struct EndIfStatement : Statement {
    /**
     * @brief Constructs an EndIfStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit EndIfStatement(int file, int line)
        : Statement(file, line, StmtType::EndIf) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<EndIfStatement>(file, line);
    }
};

/**
 * @struct UntilStatement
 * @brief Represents the condition marker statement ending a repeat-until loop block.
 */
struct UntilStatement : Statement {
    /**
     * @brief Constructs an UntilStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit UntilStatement(int file, int line)
        : Statement(file, line, StmtType::Until) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<UntilStatement>(file, line);
    }
};

/**
 * @struct BreakStatement
 * @brief Represents a loop break statement.
 */
struct BreakStatement : Statement {
    /**
     * @brief Constructs a BreakStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit BreakStatement(int file, int line)
        : Statement(file, line, StmtType::Break) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<BreakStatement>(file, line);
    }
};

/**
 * @struct ContinueStatement
 * @brief Represents a loop continue statement.
 */
struct ContinueStatement : Statement {
    /**
     * @brief Constructs a ContinueStatement node.
     * @param file Source file index.
     * @param line Source line index.
     */
    explicit ContinueStatement(int file, int line)
        : Statement(file, line, StmtType::Continue) {}

    std::unique_ptr<Statement> clone() const override {
        return std::make_unique<ContinueStatement>(file, line);
    }
};