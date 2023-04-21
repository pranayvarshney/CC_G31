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
%token INT TLET TDBG
%token TSCOL TLPAREN TRPAREN TEQUAL
%token IF ELSE LBRACE RBRACE

%type <node> Expr Stmt If_statement
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
         | StmtList If_statement
         { $$->push_back($2); }
         | Stmt TSCOL           
         { $$ = new NodeStmts(); $$->push_back($1); }
	     | StmtList Stmt TSCOL 
         { $$->push_back($2); }
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
     ;

Tail: LBRACE StmtList RBRACE
     {
    	$$ = $2;
     }
     ;

If_statement : 
     { increment_scope(); }
     IF TLPAREN Expr TRPAREN Tail ELSE Tail
     {
        $$ = new NodeIf($4, $6,$8);
        decrement_scope();
     }
     ;

Expr : TINT_LIT               
     { $$ = new NodeInt(std::stoll($1)); }
     | TIDENT
     { 
        if(symbol_table.contains($1))
            $$ = new NodeIdent($1, symbol_table.getType($1)); 
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
