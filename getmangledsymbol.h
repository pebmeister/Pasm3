#pragma once

/**
 * @file getmangledsymbol.h
 * @author Paul Baxter
*/

#include <string>

/**
 * @brief Generates a fully qualified, mangled symbol name by combining a local symbol with its parent scope.
 * 
 * Mangles scope-local symbols (such as labels prefixed with '@') using the name of the current 
 * enclosing global label or scope to ensure unique symbol resolution across different scopes.
 * 
 * @param symbol The local symbol or label identifier to mangle (e.g., "@loop").
 * @param parent_scope The enclosing parent scope or global label identifier (e.g., "MainRoutine").
 * @return std::string The fully qualified/mangled symbol string.
 */
extern std::string GetMangledSymbol(const std::string& symbol, const std::string& parent_scope);
