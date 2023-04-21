%option noyywrap

%{
#include "parser.hh"
#include <string>

extern int yyerror(std::string msg);
%}

%%

"+"       { return TPLUS; }
"-"       { return TDASH; }
"*"       { return TSTAR; }
"/"       { return TSLASH; }
";"       { return TSCOL; }
","       { return TCOMMA;}
"("       { return TLPAREN; }
")"       { return TRPAREN; }
"{"       { return TLCURR;}
"}"       { return TRCURR;}
"="       { return TEQUAL; }
"dbg"     { return TDBG; }
"let"     { return TLET; }
"fun"     { return TFUN; }
"ret"     { return TRET; } 
":"        { return TCOLON; }
"int"|"long"|"short"       { yylval.lexeme = std::string(yytext); return TTYPE; }
[0-9]+    { yylval.lexeme = std::string(yytext); return TINT_LIT; }
[a-zA-Z]+ { yylval.lexeme = std::string(yytext); return TIDENT; }
[ \t\n]   { /* skip */ }
.         { yyerror("unknown char"); }

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
        case TLCURR: s = "TLCURR"; break;
        case TRCURR: s = "TRCURR"; break;
        case TEQUAL: s = "TEQUAL"; break;
        case TCOLON: s = "TCOLON"; break;
        case TCOMMA: s = "TCOMMA"; break;
        
        case TDBG: s = "TDBG"; break;
        case TLET: s = "TLET"; break;
        case TFUN: s = "TFUN"; break;
        case TRET: s = "TRET"; break;
        case TTYPE: s = "TTYPE"; s.append("  ").append(lexeme); break;
        
        case TINT_LIT: s = "TINT_LIT"; s.append("  ").append(lexeme); break;
        case TIDENT: s = "TIDENT"; s.append("  ").append(lexeme); break;
    }

    return s;
}