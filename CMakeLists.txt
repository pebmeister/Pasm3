cmake_minimum_required(VERSION 3.20)
project(PasmParser CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ------------------------------------------------------------------------------
# 1. Build the Lexer Generator Tool
# ------------------------------------------------------------------------------
add_executable(buildlexor
    buildlexor/main.cpp
    buildlexor/RegexEngine.h
    ruletype.h
    tokenkind.h
)

# Optional: Organize header inclusion inside buildlexor source
target_include_directories(buildlexor PRIVATE
buildlexor
"${CMAKE_CURRENT_SOURCE_DIR}"
)

# ------------------------------------------------------------------------------
# 2. Custom Command & Target to Generate PasmTokenizer.hpp
# ------------------------------------------------------------------------------
set(GENERATED_TOKENIZER_HEADER "${CMAKE_CURRENT_BINARY_DIR}/PasmTokenizer.hpp")

add_custom_command(
    OUTPUT "${GENERATED_TOKENIZER_HEADER}"
    COMMAND buildlexor "${GENERATED_TOKENIZER_HEADER}"
    DEPENDS buildlexor
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Running buildlexor to generate PasmTokenizer.hpp..."
    VERBATIM
)

# Create a custom target so CMake explicitly manages the dependency step
add_custom_target(generate_lexer DEPENDS "${GENERATED_TOKENIZER_HEADER}")

# ------------------------------------------------------------------------------
# 3. Build Main Executable
# ------------------------------------------------------------------------------
add_executable(pasm_parser
    main.cpp
    opcodedict.cpp
    opcodedict.h
    opcodes.h
    ruletype.h
    tokenkind.h
    "${GENERATED_TOKENIZER_HEADER}"
)

# Ensure the generated header is found during compilation
target_include_directories(pasm_parser 
    PRIVATE 
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_BINARY_DIR}"
)

# Force the lexer generator target to execute before compiling main sources
add_dependencies(pasm_parser generate_lexer)