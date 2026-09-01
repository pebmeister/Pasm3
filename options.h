#pragma once

struct Options {
    uint16_t start_addr;
    std::string outfile;
    std::vector<std::string> include;
    std::vector<std::string>input_filenames;
	bool c64 = false;
	bool verbose = false;
	bool warnings = true;
	bool ignore_size = true;
};
