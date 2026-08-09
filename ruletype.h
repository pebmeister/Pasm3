#pragma once

enum RULE_TYPE {
    Op_Implied,
    Op_Immediate,
    Op_Absolute,
    Op_ZeroPage,
    Op_AbsoluteX,
    Op_ZeroPageX,
    Op_AbsoluteY,
    Op_ZeroPageY,
    Op_Indirect,
    Op_IndirectX,
    Op_IndirectY,
    Op_Accumulator,
    Op_Relative,
    Op_ZeroPageRelative
};

extern std::map<RULE_TYPE, std::string_view> rulemap;

#ifdef GEN_RULEMAP
std::map<RULE_TYPE, std::string> rulemap = {
    { Op_Implied, "Op_Implied" },
    { Op_Immediate, "Op_Immediate" },
    { Op_Absolute, "Op_Absolute" },
    { Op_ZeroPage, "Op_ZeroPage" },
    { Op_AbsoluteX, "Op_AbsoluteX" },
    { Op_ZeroPageX, "Op_ZeroPageX" },
    { Op_AbsoluteY, "Op_AbsoluteY" },
    { Op_ZeroPageY, "Op_ZeroPage" },
    { Op_Indirect, "Op_Indirect" },
    { Op_IndirectX, "Op_IndirectX" },
    { Op_IndirectY, "Op_IndirectY" },
    { Op_Accumulator, "Op_Accumulator" },
    { Op_Relative, "Op_Relative" },
    { Op_ZeroPageRelative, "Op_ZeroPageRelative" }
};
#endif