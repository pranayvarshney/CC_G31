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

SymbolTableStack symbol_table_stack;
std::unordered_map<std::string, int> type_table = {
    {"int", 1},
    {"long", 2},
    {"short", 0}
};

int yyerror(std::string msg);

}

%token TPLUS TDASH TSTAR TSLASH TCOLON TCOMMA
%token <lexeme> TINT_LIT TTYPE TIDENT
%token INT TLET TDBG 
%token TSCOL TLPAREN TRPAREN TEQUAL 
%token IF ELSE LBRACE RBRACE TRET TFUN

%type <node> Expr Stmt If_statement Function Return
%type <stmts> Program StmtList Tail Function_body
%type <arglist> ArgumentList Arguments
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
         | Function
         { $$ = new NodeStmts(); $$->push_back($1); }
         | StmtList Function
         { $$->push_back($2); }
         | Stmt TSCOL           
         { $$ = new NodeStmts(); $$->push_back($1); }
	     | StmtList Stmt TSCOL 
         { $$->push_back($2); }
	     ;

Stmt : TLET TIDENT TCOLON TTYPE TEQUAL Expr
     {
        if(symbol_table_stack.contains($2)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table_stack.insert($2, type_table[$4]);
            $$ = new NodeDecl($2, type_table[$4], $6, symbol_table_stack.getIdentifierOffset($2));  
        }
     }
     | TDBG Expr
     { 
        $$ = new NodeDebug($2);
     }
     ;

Function : 
     TFUN TIDENT {
        SymbolTable new_table;
        symbol_table_stack.push(new_table);
     }
     Arguments TCOLON TTYPE LBRACE Function_body RBRACE{
        if(symbol_table_stack.contains($2)) {
            yyerror("tried to redeclare function.\n");
        } else {
             symbol_table_stack.insert($2,type_table[$6]);
             $$=new NodeFunction($2,$4,type_table[$6],$8);
             symbol_table_stack.pop();
            }
    }
;


Arguments : TLPAREN ArgumentList TRPAREN
    {
        $$ = $2;
    }
    | TLPAREN TRPAREN
    { $$ = new NodeArgList(); }
    ;

ArgumentList :
    TIDENT TCOLON TTYPE
    {
        if(symbol_table_stack.contains($1)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table_stack.insert($1, type_table[$3]);
            $$ = new NodeArgList();
            $$->push_back(new NodeDecl($1, type_table[$3], new NodeInt(0), symbol_table_stack.getIdentifierOffset($1)));  
        }
    }
    | ArgumentList TCOMMA TIDENT TCOLON TTYPE
    {
        if(symbol_table_stack.contains($3)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table_stack.insert($3, type_table[$5]);
            $$->push_back(new NodeDecl($3, type_table[$5], new NodeInt(0), symbol_table_stack.getIdentifierOffset($3)));  
        }
    }
    ;
Function_body: 
     Return 
     {
        $$ = new NodeStmts();
        $$->push_back($1);
     }
     | StmtList Return
     {
         $$ = $1;
         $$->push_back($2);
     }
     | StmtList Return StmtList
     {
        $$ = $1;
        $$->push_back($2);
        $$->push_back($3);
     }
Return : TRET Expr TSCOL
    {
        $$ = $2;
    }
    |
    { $$ = new NodeInt(0); }
    ;

Tail: LBRACE StmtList RBRACE
     {
    	$$ = $2;
     }
     | LBRACE RBRACE
     {
        $$ = new NodeStmts();
     }
     ;

If_statement : 
     IF Expr {
        SymbolTable new_table;
        symbol_table_stack.push(new_table);
     }
     Tail {
        symbol_table_stack.pop();
     }
     ELSE {
        SymbolTable new_table;
        symbol_table_stack.push(new_table);
     }
     Tail
     {
        $$ = new NodeIf($2, $4,$8);
        symbol_table_stack.pop();
     }
     ;

Expr : TINT_LIT               
     { $$ = new NodeInt(std::stoll($1)); }
     | TIDENT
     { 
        if(symbol_table_stack.contains($1) || symbol_table_stack.parent_contains($1))
            $$ = new NodeIdent($1, symbol_table_stack.getType($1),symbol_table_stack.getIdentifierOffset($1)); 
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
