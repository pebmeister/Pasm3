#pragma once

#include <cstdint>
#include <utility>
/**
 * @file anonymouslabel.h
 * @author Paul Baxter
 */

/**
 * @brief Represents an anonymous label used for localized branching.
 * 
 * In assembly, anonymous labels allow for quick forward ('+') or backward ('-') 
 * jumps without polluting the symbol table. This structure tracks the label's 
 * direction, its resolved memory address, and its original location in the source.
 */
struct AnonymousLabel {
    /** 
     * @brief The direction identifier of the anonymous label.
     * 
     * Expected values are '-' for backward references or '+' for forward references.
     */
    char type;

    /** 
     * @brief The resolved Program Counter (PC) address in memory.
     */
    uint16_t address;

    /** 
     * @brief The source location identifier for relative positioning.
     * 
     * Typically stores a pair containing the file ID and the line number (or 
     * AST index) to accurately resolve which '+' or '-' is being referenced.
     */
    std::pair<int, size_t> statement_id; 
};
