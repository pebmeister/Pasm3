#pragma once
#include <vector>
#include <cctype>

class Opcode_test {
private:
    struct OP_TEST {
        std::string op;
        int mode;
        uint8_t expected;
    };

    int op_test(OP_TEST& test, int depth, bool negative);
    void build_opcode_tests(std::vector<OP_TEST>& positive_opcode_tests, std::vector<OP_TEST>& negative_opcode_tests);

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
    int passed = 0;
    int failed = 0;

    int test(int max_iterations);
};