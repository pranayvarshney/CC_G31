#ifndef SYMBOL_HH
#define SYMBOL_HH

#include <unordered_map>
#include <string>
#include <utility>
#include "ast.hh"


// Basic symbol table, just keeping track of prior existence and nothing else
struct SymbolTable {
    std::unordered_map<std::string, int> table;

    bool contains(std::string key);
    void insert(std::string key, int type);
    int getType(std::string key);
};

#endif