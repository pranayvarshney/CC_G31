#include "symbol.hh"
#include <iostream>
int curr_scope =0;

void increment_scope(){
    curr_scope++;
}
void decrement_scope(){
    curr_scope--;
}

bool SymbolTable::contains(std::string key) {
    return (table.find(key) != table.end() && table[key].scope == curr_scope);
}

void SymbolTable::insert(std::string key, int type) {
    table[key] = {
        type,
        curr_scope
    };
}

int SymbolTable::getType(std::string key) {
    return table[key].type;
}