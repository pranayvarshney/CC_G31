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
    while(s[i]==' ')
        i++;
    std::string value = "";
    std::string subvalue="";

    for(;i<(int)s.size();i++){
        if(!((s[i] >= 'a' and s[i] <= 'z') or (s[i] >= 'A' and s[i] <= 'Z'))){
            if(subvalue.size() > 0){
                if(macro_table.find(subvalue) != macro_table.end())
                    value += macro_table[subvalue];
                else
                    value += subvalue;
                subvalue = "";
            }
            value += s[i];
        }
        else
            subvalue += s[i];
    }
    if(subvalue.size() > 0){
        if(macro_table.find(subvalue) != macro_table.end())
            value += macro_table[subvalue];
        else
            value += subvalue;
        subvalue = "";
    }
 
    for(auto i:macro_table){
        if(value.find(i.first) == std::string::npos)
            yy_fatal_error("Syntax Error\n");
    }
    macro_table[key] = value;
    for(auto i: macro_table){
        if(i.second==key){
            macro_table[i.first] = macro_table[key];
        }
    }
    for(auto i:macro_table){
        if(i.first==i.second){
            yy_fatal_error("Error: Invalid Syntax");
        }
    }
    BEGIN INITIAL;
}
%%
