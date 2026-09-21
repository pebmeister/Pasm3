/**
 * @file source_manager.h
 * @brief Manages source file paths, line lookup tables, and nested include stacks.
 * @author Paul Baxter
 */

#pragma once

#include <algorithm>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

/**
 * @struct SourceManager
 * @brief Tracks loaded source files, include call stacks, and line contents during assembly.
 *
 * Provides a central registry mapping unique file IDs to file path strings, tracks active
 * include chains to prevent circular dependencies, and caches source code lines for diagnostics.
 */
struct SourceManager {
    std::vector<std::string> files;          /**< Global registry mapping file IDs (index) to file path strings. */
    std::vector<std::string> include_stack;  /**< Active include file chain used for circular dependency detection. */

    std::map<std::pair<int, int>, std::string> source; /**< Map storing source line text keyed by {fileid, lineNo}. */

    /**
     * @brief Safely looks up a file name given its registered file ID.
     * @param fileid The integer identifier associated with the file.
     * @return The file path string if valid; otherwise, `"<unknown>"`.
     */
    std::string GetFileName(int fileid) const {
        if (fileid >= 0 && fileid < static_cast<int>(files.size())) {
            return files[fileid];
        }
        return "<unknown>";
    }

    /**
     * @brief Retrieves an existing file ID or registers a new file path.
     * @param filepath The relative or absolute path of the source file.
     * @return The unique integer file ID assigned to the file.
     */
    int GetOrRegisterFile(const std::string& filepath) {
        for (int i = 0; i < static_cast<int>(files.size()); ++i) {
            if (files[i] == filepath) return i;
        }
        files.push_back(filepath);
        return static_cast<int>(files.size() - 1);
    }

    /**
     * @brief Fetches the raw text content for a specific file line.
     * @param fileid The registered file ID.
     * @param lineNo The 1-based line number.
     * @return The line text stored at the given coordinate pair.
     */
    std::string GetLine(int fileid, int lineNo) {
        return source[{fileid, lineNo}];
    }

    /**
     * @brief Pushes a file onto the active include stack with circular dependency checking.
     * @param filepath The path of the file being included.
     * @throws std::runtime_error If the file is already present in the active include stack.
     */
    void PushInclude(const std::string& filepath) {
        if (std::find(include_stack.begin(), include_stack.end(), filepath) != include_stack.end()) {
            throw std::runtime_error("Circular include detected: " + filepath);
        }
        include_stack.push_back(filepath);
    }

    /**
     * @brief Pops the top file off the active include stack upon completing tokenization/parsing.
     */
    void PopInclude() {
        if (!include_stack.empty()) {
            include_stack.pop_back();
        }
    }
};