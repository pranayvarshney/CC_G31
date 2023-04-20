/* %option prefix="yy" */
%option noyywrap
%x SCOMMENT
%x MCOMMENT

%{
#include "parser.hh"
#include <string>
#include <unordered_map>     
#include <string>     
#include <cstring>     
#include <tuple>      
 
std::pair<std::string, std::string> tokenise(char* yytext);
 
extern int yyerror(std::string msg);
 
%}

%%
 
"if"			{ return IF; }
"else"	        { return ELSE; }
"+"       { return TPLUS; }
"-"       { return TDASH; }
"*"       { return TSTAR; }
"/"       { return TSLASH; }
";"       { return TSCOL; }
"("       { return TLPAREN; }
")"       { return TRPAREN; }
"="       { return TEQUAL; }
"?"       { return TQUESTION; }
":"       { return TCOLON; }
"{"       { return LBRACE; }
"}"       { return RBRACE; }
"dbg"     { return TDBG; }
"let"     { return TLET; }
[0-9]+    { yylval.lexeme = std::string(yytext); return TINT_LIT; }
[a-zA-Z]+ { yylval.lexeme = std::string(yytext); return TIDENT; }
[ \t\n]   { /* skip */ }
.         { yyerror("unknown char"); }
"//"[^\n]*  { BEGIN (SCOMMENT);}
<SCOMMENT>[ \n]+ {BEGIN (INITIAL);} 
"/*"  { BEGIN(MCOMMENT); }
<MCOMMENT>[^*]*[*]+([^*/][^*]*[*]+)*[/]  {BEGIN(INITIAL);}
<MCOMMENT>.  {yy_fatal_error("Unterminated comment");}

%%
 
std::string token_to_string(int token, const char *lexeme) {
    std::string s;
    switch (token) {
        case TPLUS: s = "TPLUS"; break;
        case TDASH: s = "TDASH"; break;
        case TSTAR: s = "TSTAR"; break;
        case TSLASH: s = "TSLASH"; break;
        case TSCOL: s = "TSCOL"; break;
        case TLPAREN: s = "TLPAREN"; break;
        case TRPAREN: s = "TRPAREN"; break;
        case TEQUAL: s = "TEQUAL"; break;

        case TQUESTION: s = "TQUESTION"; break;
        case TCOLON: s = "TCOLON"; break;
        
        case LBRACE: s = "LBRACE"; break;
        case RBRACE: s = "RBRACE"; break;
        case IF: s = "IF"; break;
        case ELSE: s = "ELSE"; break;

        case TDBG: s = "TDBG"; break;
        case TLET: s = "TLET"; break;
        
        case TINT_LIT: s = "TINT_LIT"; s.append("  ").append(lexeme); break;
        case TIDENT: s = "TIDENT"; s.append("  ").append(lexeme); break;
    }
 
    return s;
}