%option prefix="pr"
%option noyywrap
%x DEFMODE

%{
#include "parser.hh"
#include <string>
#include <cstring>
#include <unordered_map>     
#include <string>     
#include <cstring>     
#include <tuple>      

std::unordered_map<std::string, std::string> macro_table;      
 
extern int prerror(std::string msg);
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
    while (s[i] != '\n') {
        value += s[i];
        i++;
    }

    macro_table[key] = value;
    BEGIN INITIAL;
}
%%
