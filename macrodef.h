#pragma once

#include <string>
#include <vector>
#include "PasmTokenizer.hpp"

/**
 * @file macrodef.h
 * @author Paul Baxter
 */

/**
 * @struct MacroDef
 * @brief Represents the definition and token body of an assembler macro.
 */
struct MacroDef {
    std::string name;                              /**< Identifier name of the macro. */
    std::vector<PasmTokenizer::Token> body_tokens; /**< Token sequence comprising the macro body. */
    int times_called = 0;                          /**< Invocation counter used for unique local symbol mangling during expansions. */
};
