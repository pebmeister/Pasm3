#pragma once
#include <algorithm>
#include <vector>

struct SourceManager {
    std::vector<std::string> files;          // Global registry: index = fileid
    std::vector<std::string> include_stack;  // Active include chain

	std::map<std::pair<int,int>, std::string> source;

    // Safe lookup helper
    std::string GetFileName(int fileid) const {
        if (fileid >= 0 && fileid < static_cast<int>(files.size())) {
            return files[fileid];
        }
        return "<unknown>";
    }

    // Gets existing fileid or registers a new file
    int GetOrRegisterFile(const std::string& filepath) {
        for (int i = 0; i < static_cast<int>(files.size()); ++i) {
            if (files[i] == filepath) return i;
        }
        files.push_back(filepath);
        return static_cast<int>(files.size() - 1);
    }

	std::string GetLine(int fileid, int lineNo) {
		return source[{fileid, lineNo}];
	}
	
    // Push file onto stack with circular dependency check
    void PushInclude(const std::string& filepath) {
        if (std::find(include_stack.begin(), include_stack.end(), filepath) != include_stack.end()) {
            throw std::runtime_error("Circular include detected: " + filepath);
        }
        include_stack.push_back(filepath);
    }

    // Pop file when done tokenizing/parsing
    void PopInclude() {
        if (!include_stack.empty()) {
            include_stack.pop_back();
        }
    }
	
};
