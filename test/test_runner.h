#pragma once
#include <sstream>
#include <format>
#include <string>

#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "autoloader.h"
#include "ANSI_esc.h"

#include "sourceManager.h"

class TestRunner
{

public:
    struct Test {
        SourceManager src_mgr;
        std::string source_code;
        std::vector<uint8_t> expected;
        bool negative_test;

        Test(
            SourceManager src_mgr,
            std::string_view source_code,
            std::vector<uint8_t> expected,
            bool negative_test = false) 
            : src_mgr(std::move(src_mgr)),
              source_code(std::move(source_code)),
              expected(std::move(expected)),
              negative_test(negative_test) {}
    };


    std::string error;
    std::string source;
    
    virtual std::vector<Test> create_unit_tests(int max_iterations) = 0;

    int test(int col, bool exit_on_fail, int max_iterations)
    {        
        constexpr int fileid = 0;
        std::stringstream ss;

        bool overall_passed = true;
        int passed_count = 0;
        int failed_count = 0;

        auto tests = create_unit_tests(max_iterations);
        auto total_tests = tests.size();
        PasmTokenizer tokenizer;
        Options options;
        options.verbose = false;

        for (auto& test : tests) {
            bool test_passed = false;
            try {

                std::string source_code = test.source_code;
                auto tokens = tokenizer.tokenize(source_code, fileid);
                AssemblerParser parser(tokens, options, test.src_mgr);
                auto statements = parser.ParseProgram(tokenizer);
                MultiPassAssembler assembler(options);
                assembler.Assemble(statements, test.src_mgr);

                if (test.negative_test) {
                    // Assembly succeeded when it should have thrown an exception
                    // The is needed because we can have a false fail in opcode test
                    // if an op has say abolute mode but not zero page
                    // the zero page test will succeed because it will be interpreted as absolute
                    test_passed = (test.expected != assembler.binary_output);
                    if (!test_passed) {
                        ss << "FAILED (Negative Test): Assembly succeeded on invalid input.\n";
                    }
                } else {
                    test_passed = (test.expected == assembler.binary_output);
                }
            } 
            catch (std::exception& ex) {
                if (test.negative_test) {
                    // Exception was expected
                    test_passed = true;
                } else {
                    test_passed = false;
                    ss << std::format("FAILED with exception: {}\n", ex.what());
                }
            }

            if (test_passed) {
                ++passed_count;
                
                std::cout << std::format("{} {}PASSED: {:4} of {}{}", es.column(col), 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed_count, total_tests, es.ERASE_CURSOR_EOL);
                
            } else {
                
                std::cout << std::format("{} FAILED\n{}\n", (test.negative_test ? "negative" : "positive"), test.source_code);
                ++failed_count;
                overall_passed = false;

                std::cout << std::format("{}{} PASSED: {:4} {}FAILED: {}{}", es.column(col), 
                    es.gr(es.BRIGHT_GREEN_FOREGROUND), passed_count, es.gr(es.BRIGHT_RED_FOREGROUND), failed_count,es.ERASE_CURSOR_EOL);

                
                error = ss.str();
                if (exit_on_fail) {
                    return overall_passed;
                }
            }
        }

        return !overall_passed;
    }
};