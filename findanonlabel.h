
#pragma once
#include <optional>
#include <cstdint>
#include <vector>

#include "anonymouslabel.h"
/**
 * @file findanonlabel.h
 * @author Paul Baxter
 */

/**
 * @brief Locates the address of an anonymous label relative to the current program counter.
 * 
 * This function searches a collection of anonymous labels to resolve forward 
 * (e.g., '+', '++') or backward (e.g., '-', '--') references during assembly 
 * evaluation. 
 * 
 * @param anonymous_labels A collection of parsed anonymous labels, typically sorted by location.
 * @param forward          Set to true to search ahead ('+'), or false to search behind ('-').
 * @param count            The number of labels to count or skip (e.g., 1 for '+', 2 for '++').
 * @param pc               The current Program Counter (PC) address to search relative to.
 * @return std::optional<int> The resolved memory address of the target label, or std::nullopt if it does not exist.
 */
std::optional<int> FindAnonLabel(const std::vector<AnonymousLabel>& anonymous_labels, bool forward, int count, uint16_t pc);
