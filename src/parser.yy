%define api.value.type { ParserValue }

%code requires {
#include <iostream>
#include <vector>
#include <string>

#include "parser_util.hh"
#include "symbol.hh"

}

%code {

#include <cstdlib>

extern int yylex();
extern int yyparse();

extern NodeStmts* final_values;

SymbolTable symbol_table;

int yyerror(std::string msg);

}

%token TPLUS TDASH TSTAR TSLASH LBRACE RBRACE TCOLON TQUESTION
%token <lexeme> TINT_LIT TIDENT
%token INT TLET TDBG
%token TSCOL TLPAREN TRPAREN TEQUAL
%token IF ELSE

%type <node> Expr Stmt Ternary If_statement
%type <stmts> Program StmtList Tail

%left TPLUS TDASH
%left TSTAR TSLASH

%%

Program :                
        { final_values = nullptr; }
        | StmtList
        { final_values = $1; }
	    ;

StmtList : If_statement
         { $$ = new NodeStmts(); $$->push_back($1); } 
         | Stmt TSCOL           
         { $$ = new NodeStmts(); $$->push_back($1); }
	     | StmtList Stmt TSCOL 
         { $$->push_back($2); }
	     ;

Stmt :  TLET TIDENT TEQUAL Expr
     {
        if(symbol_table.contains($2)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table.insert($2);

            $$ = new NodeDecl(Node::ASSN, $2, $4);
        }
     }
     | TDBG Expr
     { 
        $$ = new NodeDebug($2);
     }
     | TIDENT TEQUAL Expr
     {
        if(symbol_table.contains($1)) {
            $$ = new NodeDecl(Node::REASSN, $1, $3);
        } else {
            yyerror("tried to assign to undeclared variable.\n");
        }
     }
     ;

Tail: LBRACE StmtList RBRACE
    {
    	$$ = $2;
    }
;

If_statement : IF TLPAREN Expr TRPAREN Tail ELSE Tail
    {
        $$ = new NodeIf($3, $5,$7);
    }
;



Ternary : Expr TQUESTION Expr TCOLON Expr
     { $$ = new NodeTernary($1, $3, $5); };

Expr : TINT_LIT               
     { $$ = new NodeInt(stoi($1)); }
     | TIDENT
     { 
        if(symbol_table.contains($1))
            $$ = new NodeIdent($1); 
        else
            yyerror("using undeclared variable.\n");
     }
     | Expr TPLUS Expr
     { $$ = new NodeBinOp(NodeBinOp::PLUS, $1, $3); }
     | Expr TDASH Expr
     { $$ = new NodeBinOp(NodeBinOp::MINUS, $1, $3); }
     | Expr TSTAR Expr
     { $$ = new NodeBinOp(NodeBinOp::MULT, $1, $3); }
     | Expr TSLASH Expr
     { $$ = new NodeBinOp(NodeBinOp::DIV, $1, $3); }
     | TLPAREN Expr TRPAREN { $$ = $2; }
     | Ternary
     ;

%%

int yyerror(std::string msg) {
    std::cerr << "Error! " << msg << std::endl;
    exit(1);
}
