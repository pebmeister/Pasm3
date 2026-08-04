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
