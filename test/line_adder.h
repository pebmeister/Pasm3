#pragma once
#include <string>
#include <format>
#include "sourceManager.h"

class Line_Adder {
private:
    SourceManager src_mgr;
    std::string source_code;
    int fileid = 0;
    int line_num = 1;
        
public:
    
    // Overload operator() so you can call the instance like a function: adder("line");
    void operator()(std::string line = "") {
        src_mgr.source[{fileid, line_num}] = line;
        source_code += (line + "\n");
        line_num++;
    }
    
    int GetSource(std::string& source) {
        source = source_code;
        return line_num - 1;
    }

    Line_Adder(SourceManager mgr, std::string test_name, const int org) 
        : src_mgr(std::move(mgr))
        {
            src_mgr.files.push_back(test_name);

            std::string line =  std::format("; {}", test_name);
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;            

            line = "";
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;            

            line = std::format("    * = ${:04X}", org);;
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++; 

            line = "";
            src_mgr.source[{fileid, line_num}] = line;
            source_code += (line + "\n");
            line_num++;            
        }
};
