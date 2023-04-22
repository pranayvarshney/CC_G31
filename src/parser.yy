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

%type <node> Expr Stmt If_statement Function
%type <stmts> Program StmtList Tail 
%type <arglist> Arguments ArgumentList

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
     |
     Function
      ;

Function : TFUN TIDENT TLPAREN Arguments TRPAREN TCOLON TTYPE LBRACE StmtList TRET Expr RBRACE 
    {
        if(symbol_table_stack.contains($2)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare function.\n");
        } else {
            // std::vector<std::pair<std::string, int>> args = $4;
             symbol_table_stack.insert($2,type_table[$7]);
            // $$ = new NodeFunction($2, args, type_table[$7], $9, $11);
            }
        
    }
;

Arguments : ArgumentList
    { $$ = $1; }
    |
    ;

ArgumentList : TIDENT TCOLON TTYPE TCOMMA ArgumentList
    {
        $$->push_back($1, type_table[$3]);
    }
    | TIDENT TCOLON TTYPE
    {
        $$->push_back($1, type_table[$3]);
    }
    ;


Tail: LBRACE StmtList RBRACE
     {
    	$$ = $2;
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
     { 
        long long int ini = std::stoll($1);
        if (ini >= -32768 && ini <= 32767)
        {
            $$ = new NodeShort(short(std::stoi($1)));
        }
        else if (ini >= -2147483648 && ini <= 2147483647)
        {
            $$ = new NodeInt(std::stoi($1));
        }
        else
        {
            $$ = new NodeLong(std::stoll($1));
        }
        
         }
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
