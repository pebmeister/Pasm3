#include <iomanip>
#include <sstream>
#include <utility>
#include <format>
#include <fstream>
#include <sstream>
#include <exception>
#include <stack>
#include <chrono>
#include <iostream>


#include "opcodedict.h"
#include "PasmTokenizer.hpp"
#include "anonymouslabel.h"
#include "multipassassembler.h"
#include "symboltable.h"
#include "sourceManager.h"
#include "getmangledsymbol.h"
#include "opcodeinfo.h"

#include "exprNode.h"
#include "macrodef.h"
#include "utilities.h"
#include "AssemblerParser.h"
#include "utilities.h"


std::vector<PasmTokenizer::Token> LoadAndTokenizeFile(
    const std::string& filepath,
    SourceManager& src_mgr,
    const PasmTokenizer& tokenizer
) {
	
	
  src_mgr.PushInclude(filepath);
  int fileid = src_mgr.GetOrRegisterFile(filepath);
	
	int lineNo = 1;
	std::string line;
	std::string source_code;
	std::ifstream infile(filepath);
	while (std::getline(infile, line)) {
		src_mgr.source[{fileid, lineNo}] = line;
		source_code += (line + "\n");
		lineNo++;
	}
	infile.close();

    auto filetokens = tokenizer.tokenize(source_code, fileid);

    src_mgr.PopInclude();
    return filetokens;
}

std::optional<int> FindAnonLabel(const std::vector<AnonymousLabel>& anonymous_labels,  bool forward, int count, uint16_t pc) {
    auto sz = anonymous_labels.size();
    if (sz == 0) {
        return std::nullopt;
    }

    // 1. Binary search to find the first label strictly AFTER the current pc.
    size_t lo = 0;
    size_t hi = sz;

    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2; // Corrected midpoint calculation
        if (anonymous_labels[mid].address <= pc) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }

    // 'lo' is now the index of the first anonymous label after the current PC.
    size_t start_index = lo;
    int found_count = 0;

    // 2. Scan in the requested direction
    if (forward) {
        // Searching forward: start from 'start_index' and scan to the end
        while (start_index < sz) {
            auto& lbl = anonymous_labels[start_index];

            if (lbl.type == '+') {
                found_count++;
                if (found_count == count) {
                    return lbl.address;
                }
            }
            start_index++; // Moved outside the if-statement to prevent infinite loops!
        }
    }
    else {
        // Searching backward: start from 'start_index - 1' and scan down to 0
        if (start_index == 0) {
            return std::nullopt; // No labels exist before the PC
        }

        size_t back_index = start_index - 1;

        while (true) {
            auto& lbl = anonymous_labels[back_index];

            if (lbl.type == '-') {
                found_count++;
                if (found_count == count) {
                    return lbl.address;
                }
            }

            if (back_index == 0) break; // Reached the beginning
            back_index--;
        }
    }

    return std::nullopt;
}
