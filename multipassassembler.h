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
    SymbolTable vars_;
    Options options;
    bool changed = false;
    bool wait_stable = false;
    bool clean = false;
    uint16_t start_pc_;
    std::map<std::pair<int, size_t>, size_t> anon_idmap;
    std::string FormatOperand(RULE_TYPE mode, int64_t val);
    size_t GetInstructionSize(RULE_TYPE mode);

    std::string parent_scope="GLOBAL_";
    bool load_address_set = false;
    size_t pass = 1;
    size_t max_passes = 10;
	int island_counter = 0;

    // Inversion lookup table for 6502 branches
    const std::unordered_map<std::string, std::string> inverted_branches = {
        {"bne", "beq"}, {"beq", "bne"},
        {"bcc", "bcs"}, {"bcs", "bcc"},
        {"bvc", "bvs"}, {"bvs", "bvc"},
        {"bmi", "bpl"}, {"bpl", "bmi"}
    };


public:
    uint16_t load_address = 0;
    uint16_t pc = 0;
    std::vector<uint8_t> binary_output;
    std::string listing_file;

    explicit MultiPassAssembler(Options& opts) : options(opts) { start_pc_ = opts.start_addr;}  
    void Assemble(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    
private:
    void ProcessStatement(std::vector<std::unique_ptr<Statement>>& statements, std::vector<std::unique_ptr<Statement>>&new_statements, size_t& st_index, 
            std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    bool ResolutionPass(std::vector<std::unique_ptr<Statement>>& statements, std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
    void EmitFinalPass(const std::vector<std::unique_ptr<Statement>>& statements, const std::vector<AnonymousLabel>& anonymous_labels, SourceManager &src_mgr);
};
