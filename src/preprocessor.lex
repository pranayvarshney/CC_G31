%option prefix="pr"
%option noyywrap
%x DEFMODE
%x UNDEFMODE

%{
#include "parser.hh"
#include <string>
#include <cstring>
#include <unordered_map>     
#include <string>     
#include <cstring>     

extern int prerror(std::string msg);
std::unordered_map<std::string, std::string> macro_table;      
 
extern FILE* prout;
%}

%%


[a-zA-Z]+  {
                if(macro_table.find(prtext)!=macro_table.end()){
                    fprintf(prout,"%s",macro_table[prtext].c_str());
                }
                else
                {
                    fprintf(prout,"%s",prtext);
                }
            }
"#def " { BEGIN DEFMODE;}
<DEFMODE>[a-zA-Z]+[ A-Za-z0-9]*([^\n]*[\\][\n])*[^\n]*[\n] {

    std::string s = std::string(yytext);
    std::string key = "";
    int i=0;
    while (s[i] != ' ') {
        key += s[i];
        i++;
    }
    
    std::string value = "";
    i++;
    int empty = 1;
    while (s[i] != '\n') {
        value += s[i];
        i++;
    }
    if(value == ""){
        value += '1';
    }
    else{for (int i = 0; i < value.length(); i++) {
        if (value[i] != ' ') {
            empty = 0;
            break;
        }
    }
    if(empty ==1){ //EMPTY MACRO
        value += '1';
    }}
    macro_table[key] = value;
    for(auto i: macro_table){
        if(i.second==key){
            macro_table[i.first] = macro_table[key];
        } 
    }
    for(auto i: macro_table){
        if(i.first==i.second){
            yy_fatal_error("Error: Invalid Syntax");
        }
    }
    BEGIN INITIAL;
}
"#undef " {BEGIN UNDEFMODE;}
<UNDEFMODE>[a-zA-Z]+[ A-Za-z0-9]*[\n] { 
    std::string s = std::string(yytext);
    std::string key = "";
    int i=0;
    while (s[i] != ' ') {
        key += s[i];
        i++;
    }
    macro_table.erase(key);
    BEGIN INITIAL;
}
%%
