%option prefix="pr"
%option noyywrap
%x IDENTIFIER
%x DEFMODE
%x UNDEFMODE
%x SCOMMENT
%x MCOMMENT
%x DEFMODE2
%x IFDEFIDENT
%x IFDEFMODE
%x ELIFIDENT
%x ELIFMODE
%x ELSEMODE
%x SKIPMODE

%{
#include "parser.hh"
#include <string>
#include <cstring>
#include <unordered_map>     
#include <string>     
#include <cstring>     

    extern int prerror(std::string msg);
    void addValueWithCheck();
    std::unordered_map<std::string, std::string> macro_table;   
    std::string ident;  
    std::string s; 
    
    extern FILE* prout;
%}

%%

"#undef " {BEGIN UNDEFMODE;}
<UNDEFMODE>[a-zA-Z0-9]+ {
    macro_table.erase(std::string(yytext));
    BEGIN(INITIAL);
}

"#def " { BEGIN IDENTIFIER;}
<IDENTIFIER>[a-zA-Z0-9]+ {
    ident =  std::string(yytext);
    macro_table[ident] = "";
    BEGIN(DEFMODE);
}

"#ifdef " {BEGIN(IFDEFIDENT);}
<IFDEFIDENT>[a-zA-Z0-9]+ {
    ident =  std::string(yytext);
    BEGIN(IFDEFMODE);
}

<IFDEFMODE>.*"\n#endif" {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-6] = 0;
        fprintf(prout,"%s",l.c_str());
    }
    BEGIN(INITIAL);
}

<IFDEFMODE>.*"\n#elif " {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-6] = 0;
        fprintf(prout,"%s",l.c_str());
        BEGIN(SKIPMODE);
    }
    BEGIN(ELIFIDENT);
}

<IFDEFMODE>.*"\n#else" {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-5] = 0;
        fprintf(prout,"%s",l.c_str());
        BEGIN(SKIPMODE);
    }
    BEGIN(ELSEMODE);
}

<ELIFIDENT>[a-zA-Z0-9]+ {
    ident =  std::string(yytext);
    BEGIN(ELIFMODE);
}

<ELIFMODE>.*"\n#endif" {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-6] = 0;
        fprintf(prout,"%s",l.c_str());
    }
    BEGIN(INITIAL);
}

<ELIFMODE>.*"\n#elif " {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-6] = 0;
        fprintf(prout,"%s",l.c_str());
        BEGIN(SKIPMODE);
    }
    BEGIN(ELIFIDENT);
}

<ELIFMODE>.*"\n#else" {
    if(macro_table.find(ident)!=macro_table.end()){
        std::string l = std::string(prtext);
        int len = l.size();
        l[len-5] = 0;
        fprintf(prout,"%s",l.c_str());
        BEGIN(SKIPMODE);
    }
    BEGIN(ELSEMODE);
}

<ELSEMODE>.*"\n#endif" {
    std::string l = std::string(prtext);
    int len = l.size();
    l[len-6] = 0;
    fprintf(prout,"%s",l.c_str());
}

<SKIPMODE>.*"\n#endif" { }

<DEFMODE>[^\\\n]+[\n] {
    s = std::string(yytext);
    macro_table[ident] = "";
    addValueWithCheck();
    BEGIN(INITIAL);

}

<DEFMODE2>[^\\\n]+[\\][\n] {
    s = std::string(yytext);
    s[s.length()-2]=' ';
    addValueWithCheck();
    macro_table[ident] += "\n";
    BEGIN(DEFMODE2);
}
<DEFMODE>[^\\\n]+[\\][\n] {
    s = std::string(yytext);
    s[s.length()-2]=' ';
    macro_table[ident] = "";
    addValueWithCheck();
    macro_table[ident] += "\n";
    BEGIN(DEFMODE2);
}

<DEFMODE2>[^\\\n]+[\n] {
    s = std::string(yytext);
    addValueWithCheck();
    BEGIN INITIAL;
}

<DEFMODE>[ ]*[\n]* {
    macro_table[ident] = "1";
    BEGIN(INITIAL);
}

[a-zA-Z0-9]+  {
    if(macro_table.find(prtext)!=macro_table.end()){
        fprintf(prout,"%s",macro_table[prtext].c_str());
    }
    else
    {
        fprintf(prout,"%s",prtext);
    }
}

"//"[^\n]*  { BEGIN (SCOMMENT);}
<SCOMMENT>[ \n]+ {BEGIN (INITIAL);} 
"/*"  { BEGIN(MCOMMENT); }
<MCOMMENT>[^*]*[*]+([^*/][^*]*[*]+)*[/]  {BEGIN(INITIAL);}
<MCOMMENT>.  {yy_fatal_error("Unterminated comment");}
[ \n]+ { fprintf(prout,"%s",prtext);}

%%

void addValueWithCheck(){
    std::string value = "";
    std::string subvalue="";
    int start = 0;
    for(;start<(int)s.size();start++){
        if(!((s[start] >= 'a' and s[start] <= 'z') or (s[start] >= 'A' and s[start] <= 'Z'))){
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
