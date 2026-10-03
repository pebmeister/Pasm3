#pragma once
#include <vector>
#include <cctype>


#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"
#include "ANSI_esc.h"
#include "test_runner.h"


class Opcode_test  : public TestRunner {

private:

    struct OP_TEST {
        std::string_view op;
        int mode;
        uint8_t expected;
        bool negative_test;
    };

    Test make_unit_test(OP_TEST& test, int max);
  
    int test_num = 0;

    const int fileid = 0;
    const int abs_min = 0x0100;
    const int abs_max = 0xFFFF;
    
    const int rel_min = -128;
    const int rel_offset = 2;
    const int zp_rel_offset = 3;
    const int rel_max = 127;

    uint8_t opr_immediate = 0;
    uint8_t opr_zeropage = 0;
    uint8_t opr_zeropagex = 0;
    uint8_t opr_zeropagey = 0;
    uint8_t opr_indirectx = 0;
    uint8_t opr_indirecty = 0;
    int16_t opr_relative = rel_min + rel_offset;
    int16_t opr_zprelative = rel_min + zp_rel_offset;
    uint8_t opr_zprel_addr = rel_min;
    uint16_t opr_absolute = abs_min;
    uint16_t opr_absolutex = abs_min;
    uint16_t opr_absolutey = abs_min;
    uint16_t opr_indirect = abs_min;

public:
    std::vector<Test> create_unit_tests(int max_iterations = 255) override
    {
        std::vector<Opcode_test::Test> tests;
       
        for (auto&[_, info]: opcodeDict) {
            auto& op = info.mnemonic;
            for (int mode = RULE_TYPE::Op_Implied; mode <= RULE_TYPE::Op_ZeroPageRelative; ++mode) {
                auto modeIt = info.mode_to_opcode.find(static_cast<RULE_TYPE>(mode));
                if (modeIt == info.mode_to_opcode.end()) {
                    OP_TEST op_negative_test = {op, mode, 0, true};
                    tests.push_back(make_unit_test(op_negative_test, max_iterations));
                }
                else {
                    auto [opcode, _] = modeIt->second;
                    OP_TEST op_positive_test = {op, mode, opcode, false};
                    tests.push_back(make_unit_test(op_positive_test, max_iterations));
                }
            }
        }
        return tests;
    }
};