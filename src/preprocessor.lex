%option prefix="pr"
%option noyywrap
%x DEFMODE

%{
#include "parser.hh"
#include <string>
#include <unordered_map>     
#include <string>     
#include <cstring>     
#include <tuple>      

std::unordered_map<std::string, std::string> macro_table;      
 
extern int prerror(std::string msg);
 
%}

%%

"#def " { BEGIN DEFMODE;}
<DEFMODE>[a-zA-Z]+[ A-Za-z0-9]* { 
    std::string s = std::string(yytext);
    std::string key = "";
    int i=5;
    while (s[i] != ' ') {
        key += s[i];
        i++;
    }
    
    std::string value = "";
    i++;
    while (s[i] != '\0') {
        value += s[i];
        i++;
    }
    macro_table[key] = value;
    BEGIN INITIAL;
}
. {printf("%s",prtext);}
%%
