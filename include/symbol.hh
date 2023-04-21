#ifndef SYMBOL_HH
#define SYMBOL_HH

#include <unordered_map>
#include <string>
#include <utility>
#include "ast.hh"

// Basic symbol table, just keeping track of prior existence and nothing else4
struct TableEntry {
    int type;
    int scope;
};
struct SymbolTable {
    std::unordered_map<std::string, TableEntry> table;

    bool contains(std::string key);
    void insert(std::string key, int type);
    int getType(std::string key);
};

void increment_scope();
void decrement_scope();

#endif