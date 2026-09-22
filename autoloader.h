// written by Paul Baxter
#pragma once

#include <vector>
#include <string>
#include <cstdint>

/**
 * @brief Generates and patches the Commodore 64 autostart bootstrap loader binary.
 * @param filename The target PRG filename to load from disk.
 * @param addr The target execution/load address of the main program.
 * @return std::vector<uint8_t> The complete, ready-to-write LOADER.PRG binary array.
 */
std::vector<uint8_t> CreateAutoLoader(const std::string& filename, uint16_t addr);