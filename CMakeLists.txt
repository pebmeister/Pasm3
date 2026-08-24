cmake_minimum_required(VERSION 3.20)
project(PasmParser CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ------------------------------------------------------------------------------
# Optimization & Compiler Flags
# ------------------------------------------------------------------------------

# Optimize Release builds for maximum speed
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        $<$<CONFIG:Release>:-O3>
        $<$<CONFIG:Release>:-Wall>
    )
elseif(MSVC)
    add_compile_options(
        $<$<CONFIG:Release>:/O2>
        $<$<CONFIG:Release>:/W4>
    )
endif()

# Enable link-time optimization where supported
include(CheckIPOSupported)

check_ipo_supported(
    RESULT ipo_supported
    OUTPUT ipo_error
    LANGUAGES CXX
)

if(ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
else()
    message(WARNING "IPO/LTO not supported: ${ipo_error}")
endif()

# ------------------------------------------------------------------------------
# 1. Build the Lexer Generator Tool
# ------------------------------------------------------------------------------

add_executable(buildlexor
    buildlexor/main.cpp
    buildlexor/RegexEngine.h
	tokenkind.h
)

target_include_directories(buildlexor PRIVATE
    buildlexor
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# ------------------------------------------------------------------------------
# 2. Custom Command to Generate PasmTokenizer.hpp
# ------------------------------------------------------------------------------

set(GENERATED_TOKENIZER_HEADER
    "${CMAKE_CURRENT_BINARY_DIR}/PasmTokenizer.hpp"
)

add_custom_command(
    OUTPUT "${GENERATED_TOKENIZER_HEADER}"
    COMMAND $<TARGET_FILE:buildlexor> "${GENERATED_TOKENIZER_HEADER}"
    DEPENDS buildlexor
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Running buildlexor to generate PasmTokenizer.hpp..."
    VERBATIM
)

# ------------------------------------------------------------------------------
# 3. Build Main Executable
# ------------------------------------------------------------------------------

add_executable(pasm_parser
    main.cpp
    opcodedict.cpp
	multipassassembler.cpp
	utilities.cpp
	anonymouslabel.h
	exprNode.h
	findanonlabel.h
	getmangledsymbol.h
	multipassassembler.h
	opcodedict.h
	opcodeinfo.h
	opcodes.h
	ruletype.h
	sourceManager.h
	statement.h
	symboltable.h
	tokenkind.h
	macrodef.h
	utilities.h
	AssemblerParser.h
    "${GENERATED_TOKENIZER_HEADER}"
)

target_include_directories(pasm_parser PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}"
)
