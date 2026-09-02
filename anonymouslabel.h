#pragma once

struct AnonymousLabel {
    char type;             // '-' or '+'
    uint16_t address;      // PC address in memory
    std::pair<int, size_t> statement_id;   // Sequential statement/AST index for relative position
};
