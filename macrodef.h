#pragma once

struct MacroDef {
    std::string name;
    std::vector<PasmTokenizer::Token> body_tokens;
    int times_called = 0;
};
