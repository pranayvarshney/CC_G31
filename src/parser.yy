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

%type <node> Expr Stmt If_statement Function Return Function_call
%type <stmts> Program StmtList Tail
%type <arglist> ArgumentList Arguments Function_call_arg Function_call_arg_list
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
         { $$=$1;$$->push_back($2); }
         | Function
         { $$ = new NodeStmts(); $$->push_back($1); }
         | StmtList Function
         { $$=$1;$$->push_back($2); }
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
            if($6->get_type()<type_table[$4]){
                $6->set_type(type_table[$4]);
            }
            symbol_table_stack.insert($2, type_table[$4]);
            $$ = new NodeDecl($2, type_table[$4], $6, symbol_table_stack.getIdentifierOffset($2));  
        }
     }
     | TDBG Expr
     { 
        $$ = new NodeDebug($2);
     }
     | Function_call
     {
        $$ = $1;
     }
     | Return
     ;

Function : 
     TFUN TIDENT Arguments TCOLON TTYPE{
        symbol_table_stack.insert($2,type_table[$5]);
        SymbolTable new_table;
        symbol_table_stack.push(new_table);
     } LBRACE StmtList RBRACE{
        if(symbol_table_stack.contains($2)) {
            yyerror("tried to redeclare function.\n");
        } else {
            $$=new NodeFunction($2,$3,type_table[$5],$8,symbol_table_stack.getIdentifierOffset($2));
            symbol_table_stack.pop();
            std::string func_name = $2;
            for (auto stmt : $8->list) {
                auto decl = dynamic_cast<NodeDecl*>(stmt);
                if (decl) {
                    decl->set_func_name(func_name);
                }
            }
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
            $$->push_back(new NodeIdent($1, type_table[$3], symbol_table_stack.getIdentifierOffset($1)));  
        }
    }
    | ArgumentList TCOMMA TIDENT TCOLON TTYPE
    {
        if(symbol_table_stack.contains($3)) {
            // tried to redeclare variable, so error
            yyerror("tried to redeclare variable.\n");
        } else {
            symbol_table_stack.insert($3, type_table[$5]);
            $$->push_back(new NodeIdent($3, type_table[$5], symbol_table_stack.getIdentifierOffset($3)));  
        }
    }
    ;

Return : TRET Expr
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
        if($2->isIntLit()){
            if($2->to_string() != "0"){
                $$ = $4;
            }
            else{
                $$ = $8;
            }
            symbol_table_stack.pop();
        }
        else{
            $$ = new NodeIf($2, $4,$8);
            symbol_table_stack.pop();
        }
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
     | Function_call 
     |Expr TPLUS Expr
     { 
        if($1->get_type()==2 ||$3->get_type()==2 ){
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeLong*>($3)) {
                
                } else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeLong*>($3))) {
                   ini = dynamic_cast<NodeShort*>($1)->getValue() + dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() + dynamic_cast<NodeShort*>($3)->getValue();
                 }
                else if ((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeLong*>($3))) {
                   
                   ini = dynamic_cast<NodeInt*>($1)->getValue() + dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() + dynamic_cast<NodeInt*>($3)->getValue();
                 }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                //  yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::PLUS, $1, $3);
            }
        }
        else if($1->get_type()==1 || $3->get_type()==1){
            
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeInt*>($3)) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() + dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeInt*>($3))) {
                    ini = dynamic_cast<NodeShort*>($1)->getValue() + dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() + dynamic_cast<NodeShort*>($3)->getValue();
                }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                // yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::PLUS, $1, $3);
            }
        }
        else{
             if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                ini = dynamic_cast<NodeShort*>($1)->getValue() + dynamic_cast<NodeShort*>($3)->getValue();
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                $$ = new NodeBinOp(NodeBinOp::PLUS, $1, $3);
            }
        }
     }
     | Expr TDASH Expr
    { 
        if($1->get_type()==2 ||$3->get_type()==2 ){
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeLong*>($3)) {
                
                } else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeLong*>($3))) {
                   ini = dynamic_cast<NodeShort*>($1)->getValue() - dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() - dynamic_cast<NodeShort*>($3)->getValue();
                 }
                else if ((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeLong*>($3))) {
                   
                   ini = dynamic_cast<NodeInt*>($1)->getValue() - dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() - dynamic_cast<NodeInt*>($3)->getValue();
                 }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                //  yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::MINUS, $1, $3);
            }
        }
        else if($1->get_type()==1 || $3->get_type()==1){
            
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeInt*>($3)) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() - dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeInt*>($3))) {
                    ini = dynamic_cast<NodeShort*>($1)->getValue() - dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() - dynamic_cast<NodeShort*>($3)->getValue();
                }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                // yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::MINUS, $1, $3);
            }
        }
        else{
             if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                ini = dynamic_cast<NodeShort*>($1)->getValue() - dynamic_cast<NodeShort*>($3)->getValue();
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                $$ = new NodeBinOp(NodeBinOp::MINUS, $1, $3);
            }
        }
     }
     | Expr TSTAR Expr
      { 
        if($1->get_type()==2 ||$3->get_type()==2 ){
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeLong*>($3)) {
                
                } else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeLong*>($3))) {
                   ini = dynamic_cast<NodeShort*>($1)->getValue() * dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() * dynamic_cast<NodeShort*>($3)->getValue();
                 }
                else if ((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeLong*>($3))) {
                   
                   ini = dynamic_cast<NodeInt*>($1)->getValue() * dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() * dynamic_cast<NodeInt*>($3)->getValue();
                 }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                //  yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::MULT, $1, $3);
            }
        }
        else if($1->get_type()==1 || $3->get_type()==1){
            
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeInt*>($3)) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() * dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeInt*>($3))) {
                    ini = dynamic_cast<NodeShort*>($1)->getValue() * dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() * dynamic_cast<NodeShort*>($3)->getValue();
                }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                // yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::MULT, $1, $3);
            }
        }
        else{
             if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                ini = dynamic_cast<NodeShort*>($1)->getValue() * dynamic_cast<NodeShort*>($3)->getValue();
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                $$ = new NodeBinOp(NodeBinOp::MULT, $1, $3);
            }
        }
     }
     | Expr TSLASH Expr
       { 
        if($1->get_type()==2 ||$3->get_type()==2 ){
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeLong*>($3)) {
                
                } else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeLong*>($3))) {
                   ini = dynamic_cast<NodeShort*>($1)->getValue() / dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeLong*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() / dynamic_cast<NodeShort*>($3)->getValue();
                 }
                else if ((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeLong*>($3))) {
                   
                   ini = dynamic_cast<NodeInt*>($1)->getValue() / dynamic_cast<NodeLong*>($3)->getValue();
                } 
                else {
                    ini = dynamic_cast<NodeLong*>($1)->getValue() / dynamic_cast<NodeInt*>($3)->getValue();
                 }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                //  yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::DIV, $1, $3);
            }
        }
        else if($1->get_type()==1 || $3->get_type()==1){
            
            if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                if (dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeInt*>($3)) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() / dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if ((dynamic_cast<NodeShort*>($1) && dynamic_cast<NodeInt*>($3))) {
                    ini = dynamic_cast<NodeShort*>($1)->getValue() / dynamic_cast<NodeInt*>($3)->getValue();
                } 
                else if((dynamic_cast<NodeInt*>($1) && dynamic_cast<NodeShort*>($3))) {
                    ini = dynamic_cast<NodeInt*>($1)->getValue() / dynamic_cast<NodeShort*>($3)->getValue();
                }
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                // yyerror("here");
                $$ = new NodeBinOp(NodeBinOp::DIV, $1, $3);
            }
        }
        else{
             if($1->isIntLit() && $3->isIntLit()) {
                long long int ini = 0;
                ini = dynamic_cast<NodeShort*>($1)->getValue() / dynamic_cast<NodeShort*>($3)->getValue();
                if (ini >= -32768 && ini <= 32767)
                {
                    $$ = new NodeShort(short(ini));
                }
                else if (ini >= -2147483648 && ini <= 2147483647)
                {
                    $$ = new NodeInt(int(ini));
                }
                else
                {
                    $$ = new NodeLong(ini);
                }
            } else {
                $$ = new NodeBinOp(NodeBinOp::DIV, $1, $3);
            }
        }
     }
     | TLPAREN Expr TRPAREN { $$ = $2; }
     ;

Function_call : TIDENT Function_call_arg
    {
        if(symbol_table_stack.contains($1) || symbol_table_stack.parent_contains($1))
            $$ = new NodeFunctionCall($1, $2,symbol_table_stack.getIdentifierOffset($1)); 
        else
            yyerror("Caliing undeclared function.\n");
    }
    ;
Function_call_arg : TLPAREN Function_call_arg_list TRPAREN
    {
        $$ = $2;
    }
    | TLPAREN TRPAREN
    {
        $$ = new NodeArgList();
    }
    ;
Function_call_arg_list: 
    TINT_LIT{
        $$ = new NodeArgList();
        long long int ini = std::stoll($1);
        if (ini >= -32768 && ini <= 32767)
        {
            $$->push_back_call(new NodeShort(short(ini)));
        }
        else if (ini >= -2147483648 && ini <= 2147483647)
        {
            $$->push_back_call(new NodeInt(int(ini)));
        }
        else
        {
            $$->push_back_call(new NodeLong(ini));
        }
    }
    | TIDENT
    {
        if(symbol_table_stack.contains($1) || symbol_table_stack.parent_contains($1)){
            $$ = new NodeArgList();
            $$->push_back_call(new NodeIdent($1, symbol_table_stack.getType($1),symbol_table_stack.getIdentifierOffset($1))); 
        }
        else
            yyerror("using undeclared variable.\n");
    }
    | Function_call_arg_list TCOMMA TIDENT
    {
        if(symbol_table_stack.contains($3) || symbol_table_stack.parent_contains($3))
            $$->push_back_call(new NodeIdent($3, symbol_table_stack.getType($3),symbol_table_stack.getIdentifierOffset($3))); 
        else
            yyerror("using undeclared variable.\n");
    }
    | Function_call_arg_list TCOMMA TINT_LIT
    {
        long long int ini = std::stoll($3);
        if (ini >= -32768 && ini <= 32767)
        {
            $$->push_back_call(new NodeShort(short(ini)));
        }
        else if (ini >= -2147483648 && ini <= 2147483647)
        {
            $$->push_back_call(new NodeInt(int(ini)));
        }
        else
        {
            $$->push_back_call(new NodeLong(ini));
        }
    }
%%

int yyerror(std::string msg) {
    std::cerr << "Error! " << msg << std::endl;
    exit(1);
}
