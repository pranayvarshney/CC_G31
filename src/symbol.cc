#include "symbol.hh"

bool SymbolTable::contains(std::string key) {
    return table.find(key) != table.end();
}

void SymbolTable::insert(std::string key, int type) {
    table[key] = type;
}

int SymbolTable::getType(std::string key) {
    return table[key];
}