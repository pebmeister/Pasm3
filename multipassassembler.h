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
#include "options.h"

class MultiPassAssembler {
private:
    SymbolTable symbols_;
    Options options;
    uint16_t start_pc_;
    std::map<std::pair<int, size_t>, size_t> anon_idmap;
    std::string FormatOperand(RULE_TYPE mode, int64_t val);
    size_t GetInstructionSize(RULE_TYPE mode);

    std::string parent_scope="GLOBAL_";
    bool load_address_set = false;
    size_t pass = 1;
    size_t max_passes = 10;

public:
    uint16_t load_address = 0;
    std::vector<uint8_t> binary_output;
    std::string listing_file;

    explicit MultiPassAssembler(Options& opts) : options(opts) { start_pc_ = opts.start_addr;}  
    void Assemble(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    
private:
    bool ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    void EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
};
