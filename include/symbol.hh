#ifndef SYMBOL_HH
#define SYMBOL_HH

#include <unordered_map>
#include <stack>
#include <string>
#include <utility>
#include "ast.hh"

// Basic symbol table, just keeping track of prior existence and nothing else4
struct SymbolTable {
    std::unordered_map<std::string, int> table;

    bool contains(std::string key);
    void insert(std::string key, int type);
    int getType(std::string key);
};

struct SymbolTableStack {
    std::stack<SymbolTable> tables;

    bool contains(std::string key);
    bool parent_contains(std::string key);
    void insert(std::string key, int type);
    int getType(std::string key);

    void currentScope();

    void push(SymbolTable table);
    void pop();

    int getIdentifierOffset(std::string key);
};


#endif