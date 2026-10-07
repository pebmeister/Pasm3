#include <sstream>
#include <format>
#include <string>

#include "ruletype.h"
#include "tokenkind.h"

#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "macrodef.h"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "d64.h"
#include "autoloader.h"
#include "ANSI_esc.h"

#include "macro_test.h"


Macro_test::Test Macro_test::create_macro_test(int max)
{
    constexpr int fileid = 0;
    constexpr int org = 0x1000;
    SourceManager src_mgr;
    int line_num = 1;
    std::string source_code;
    std::vector<uint8_t> expected_output;

    src_mgr.files.push_back("Macro_test");

    auto add_line = [&](std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    };

    add_line(std::format("    * = {}", org));

    // Base Case Macro: _BYTE1
    add_line(".macro _BYTE1");
    add_line("    .byte \\1");
    add_line(".endm");
    add_line();

    // Dynamically generate macros (_BYTE2 through _BYTE{max})
    for (int sz = 2; sz <= max; sz++) {
        add_line(std::format(".macro _BYTE{}", sz));

        // Call previous macro: _BYTE{sz-1} \1, \2, ..., \(sz-1)
        std::string line1 = std::format("    _BYTE{} ", sz - 1);
        for (int i = 1; i < sz; ++i) {
            line1 += std::format("\\{}{}", i, (i < sz - 1) ? ", " : "");
        }
        add_line(line1);

        // Emit the last byte: .byte \sz
        add_line(std::format("    .byte \\{}", sz));

        add_line(".endm");
        add_line();
    }

    // Invoke every generated macro from 1 to max
    for (int sz = 1; sz <= max; sz++) {
        std::string test_call = std::format("_BYTE{} ", sz);
        for (int i = 1; i <= sz; ++i) {
            uint8_t byte_val = static_cast<uint8_t>(i);
            test_call += std::format("${:02X}{}", byte_val, (i < sz) ? ", " : "");
            expected_output.push_back(byte_val);

            if (org + expected_output.size() >= 0xFFFF) {
                throw std::runtime_error("PC exceeded 0xFFFF. Lower max iteration.");
            }
        }
        add_line(test_call);
    }

    return Test(src_mgr, source_code, expected_output, false);
}
