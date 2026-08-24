#pragma once
#include <optional>
#include <cstdint>

#include "anonymouslabel.h"

std::optional<int> FindAnonLabel(const std::vector<AnonymousLabel>& anonymous_labels,  bool forward, int count, uint16_t pc);
