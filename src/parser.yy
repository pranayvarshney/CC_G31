%define api.value.type { ParserValue }

%code requires {
#include <iostream>
#include <vector>
#include <string>
#include <unordered_map>

#include "parser_util.hh"
#include "symbol.hh"

}

%code {

#include <cstdlib>

extern int yylex();
extern int yyparse();

extern NodeStmts* final_values;

SymbolTable symbol_table;
std::unordered_map<std::string, int> type_table = {
    {"int", 1},
    {"long", 2},
    {"short", 0}
};

int yyerror(std::string msg);

}

%token TPLUS TDASH TSTAR TSLASH TCOLON 
%token <lexeme> TINT_LIT TTYPE TIDENT
%token INT TLET TDBG TRET TFUN 
%token TSCOL TLPAREN TRPAREN TEQUAL TCOMMA TLCURR TRCURR

%type <node> Expr Stmt Function ArgumentList
%type <stmts> Program StmtList 

%left TPLUS TDASH
%left TSTAR TSLASH

%%

Program :                
        { final_values = nullptr; }
        | StmtList TSCOL 
        { final_values = $1; }
	    ;

StmtList : Stmt                
         { $$ = new NodeStmts(); $$->push_back($1); }
	     | StmtList TSCOL Stmt 
         { $$->push_back($3); }
	     ;

Stmt : TLET TIDENT TCOLON TTYPE TEQUAL Expr
     {
        if(symbol_table.contains($2)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table.insert($2, type_table[$4]);
            $$ = new NodeDecl($2, type_table[$4], $6);  
        }
     }
     | TDBG Expr
     { 
        $$ = new NodeDebug($2);
     }
     |
     Function
      ;

Function : TFUN TIDENT TLPAREN Arguments TRPAREN TCOLON TTYPE TLCURR StmtList TRET Expr TRCURR 
    {
        if(symbol_table.contains($2)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare function.\n");
        } else {
            // symbol_table.insert($2, type_table[$2]);
            // $$ = new NodeFunction($2, $4, type_table[$6], $8, type_table[$10], $13);
        }
    }
;

Arguments : ArgumentList
    | 

ArgumentList : TIDENT TCOLON TTYPE TCOMMA ArgumentList
    {
        // $$.push_back(std::make_pair($1, type_table[$3]));
    }
    | TIDENT TCOLON TTYPE
    {
        // $$.push_back(std::make_pair($1, type_table[$3]));
    }
    ;


Expr : TINT_LIT               
     { $$ = new NodeInt(std::stoll($1)); }
     | TIDENT
     { 
        if(symbol_table.contains($1))
            $$ = new NodeIdent($1); 
        else
            yyerror("using undeclared variable.\n");
     }
     | Expr TPLUS Expr
     { 
        if($1->isIntLit() && $3->isIntLit()) {
            int val = dynamic_cast<NodeInt*>($1)->getValue() + dynamic_cast<NodeInt*>($3)->getValue();
            $$ = new NodeInt(val);
        } else {
            $$ = new NodeBinOp(NodeBinOp::PLUS, $1, $3);
        }
     }
     | Expr TDASH Expr
     { 
        if($1->isIntLit() && $3->isIntLit()) {
            int val = dynamic_cast<NodeInt*>($1)->getValue() - dynamic_cast<NodeInt*>($3)->getValue();
            $$ = new NodeInt(val);
        } else {
            $$ = new NodeBinOp(NodeBinOp::MINUS, $1, $3);
        }
     }
     | Expr TSTAR Expr
     { 
        if($1->isIntLit() && $3->isIntLit()) {
            int val = dynamic_cast<NodeInt*>($1)->getValue() * dynamic_cast<NodeInt*>($3)->getValue();
            $$ = new NodeInt(val);
        } else {
            $$ = new NodeBinOp(NodeBinOp::MULT, $1, $3);
        }
     }
     | Expr TSLASH Expr
     { 
        if($1->isIntLit() && $3->isIntLit()) {
            int val = dynamic_cast<NodeInt*>($1)->getValue() / dynamic_cast<NodeInt*>($3)->getValue();
            $$ = new NodeInt(val);
        } else {
            $$ = new NodeBinOp(NodeBinOp::DIV, $1, $3);
        }
     }
     | TLPAREN Expr TRPAREN { $$ = $2; }
     ;


%%

int yyerror(std::string msg) {
    std::cerr << "Error! " << msg << std::endl;
    exit(1);
}
