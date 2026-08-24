#pragma once
#include <map>
#include <memory>
#include <vector>
#include <cstdint>
#include <unordered_map>

#include "ruletype.h"
#include "anonymouslabel.h"
#include "symboltable.h"
#include "statement.h"
#include "sourceManager.h"

class MultiPassAssembler {
private:
    SymbolTable symbols_;
    uint16_t start_pc_{0xC000};
    std::map<std::pair<int, size_t>, size_t> anon_idmap;
    std::string FormatOperand(RULE_TYPE mode, int64_t val);
	size_t GetInstructionSize(RULE_TYPE mode);

	
public:
    explicit MultiPassAssembler(uint16_t start_pc = 0xC000) : start_pc_(start_pc) {}
	
    void Assemble(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);

private:
    bool ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    void EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
};
