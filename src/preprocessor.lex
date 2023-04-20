%option prefix="pr"
%option noyywrap
%x IDENTIFIER
%x DEFMODE
%x UNDEFMODE
%x SCOMMENT
%x MCOMMENT
%x DEFMODE2
%x SKIPMODE
%x IFDEFIDENT
%x IFDEFMODE
%x ELIFIDENT
%x ELIFMODE
%x ELSEMODE

%{
#include "parser.hh"
#include <string>
#include <cstring>
#include <unordered_map>     
#include <string>     
#include <cstring>     

    extern int prerror(std::string msg);
    void addValueWithCheck();
    std::string modIdent(std::string l);
    std::unordered_map<std::string, std::string> macro_table;   
    std::string ident;  
    std::string s; 
    
    extern FILE* prout;
%}

%%


%%

void addValueWithCheck(){
    std::string value = "";
    std::string subvalue="";
    int start = 0;
    for(;start<(int)s.size();start++){
        if(!((s[start] >= 'a' and s[start] <= 'z') or (s[start] >= 'A' and s[start] <= 'Z')) and !(s[start]>='0' and s[start]<='9')){
            if(subvalue.size() > 0){
                if(macro_table.find(subvalue) != macro_table.end())
                    value += macro_table[subvalue];
                else
                     value += subvalue;
                subvalue = "";
            }
            value += s[start];
        }
        else
            subvalue += s[start];
    }
    if(subvalue.size() > 0){
        if(macro_table.find(subvalue) != macro_table.end())
            value += macro_table[subvalue];
        else
            value += subvalue;
        subvalue = "";
    }

    macro_table[ident] += value;
    printf("%s\n",macro_table[ident].c_str());
    for(auto i: macro_table){
        if(i.second==ident){
            macro_table[i.first] = macro_table[ident];
        }
    }
    for(auto i:macro_table){
        if(i.first==i.second){
            yy_fatal_error("Error: Invalid Syntax");
        }
    }
}

std::string modIdent(std::string l){
    std::string value = "";
    std::string subvalue="";
    int start = 0;
    for(;start<(int)l.size();start++){
        if(!((l[start] >= 'a' and l[start] <= 'z') or (l[start] >= 'A' and l[start] <= 'Z')) and !(l[start]>='0' and l[start]<='9')){
            if(subvalue.size() > 0){
                if(macro_table.find(subvalue) != macro_table.end())
                    value += macro_table[subvalue];
                else
                     value += subvalue;
                subvalue = "";
            }
            value += l[start];
        }
        else
            subvalue += l[start];
    }
    if(subvalue.size() > 0){
        if(macro_table.find(subvalue) != macro_table.end())
            value += macro_table[subvalue];
        else
            value += subvalue;
        subvalue = "";
    }
    return value;
}