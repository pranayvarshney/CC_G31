#include "symbol.hh"
#include <iostream>

bool SymbolTable::contains(std::string key) {
    return (table.find(key) != table.end());
}

void SymbolTable::insert(std::string key, int type) {
    table[key]=type;
}

int SymbolTable::getType(std::string key) {
    return table[key];
}

bool SymbolTableStack::contains(std::string key) {
    if(tables.empty()) {
        return false;
    }
    return tables.top().contains(key);
}

bool SymbolTableStack::parent_contains(std::string key) {
    std::stack<SymbolTable> temp = tables;

    while (!temp.empty()) {
        if (temp.top().contains(key)) {
            return true;
        }
        temp.pop();
    }
    return false;
}

void SymbolTableStack::insert(std::string key, int type) {
    if (tables.empty())
    {
        SymbolTable table;
        tables.push(table);
    }
    
    tables.top().insert(key, type);
}

int SymbolTableStack::getType(std::string key) {
    std::stack<SymbolTable> temp = tables;
    while (!temp.empty()) {
        if (temp.top().contains(key)) {
            return temp.top().getType(key);
        }
        temp.pop();
    }
    return -1;
}

void SymbolTableStack::push(SymbolTable table) {
    tables.push(table);
}

void SymbolTableStack::pop() {
    tables.pop();
}

void SymbolTableStack::currentScope() {
    std::cout<<"current scope\n";
    int t = tables.size();
    std::stack<SymbolTable> temp = tables;
    while (!temp.empty()) {
        std::cout<<"scope: "<<t<<"\n";
        for (auto it = temp.top().table.begin(); it != temp.top().table.end(); ++it) {
            std::cout << it->first << " => " << it->second << '\n';
        }
        t--;
        temp.pop();
    }
}

int SymbolTableStack::getIdentifierOffset(std::string key) {
    std::stack<SymbolTable> temp = tables;
    int offset = tables.size();
    while (!temp.empty()) {
        if (temp.top().contains(key)) {
            // std::cout<<"offset: "<<offset<<"\n";
            return offset;
        }
        offset--;
        temp.pop();
    }
    return offset;
}