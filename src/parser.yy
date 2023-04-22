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
            yyerror#include "llvmcodegen.hh"
#include "ast.hh"
#include <iostream>
#include <llvm/Support/FileSystem.h>
#include <llvm/IR/Constant.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/GlobalValue.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Bitcode/BitcodeWriter.h>
#include <vector>

#define MAIN_FUNC compiler->module.getFunction("main")

/*
The documentation for LLVM codegen, and how exactly this file works can be found
ins `docs/llvm.md`
*/

void LLVMCompiler::compile(Node *root)
{
    /* Adding reference to print_i in the runtime library */
    // void printi();
    FunctionType *printi_func_type = FunctionType::get(
        builder.getVoidTy(),
        {builder.getInt64Ty()},
        false
    );
    Function::Create(
        printi_func_type,
        GlobalValue::ExternalLinkage,
        "printi",
        &module);
    /* we can get this later
        module.getFunction("printi");
    */

    /* Main Function */
    // int main();
    FunctionType *main_func_type = FunctionType::get(
        builder.getInt32Ty(), {}, false /* is vararg */
    );
    Function *main_func = Function::Create(
        main_func_type,
        GlobalValue::ExternalLinkage,
        "main",
        &module);

    // create main function block
    BasicBlock *main_func_entry_bb = BasicBlock::Create(
        *context,
        "entry",
        main_func);

    // move the builder to the start of the main function block
    builder.SetInsertPoint(main_func_entry_bb);

    root->llvm_codegen(this);

    // return 0;
    builder.CreateRet(builder.getInt32(0));
}

void LLVMCompiler::dump()
{
    outs() << module;
}

void LLVMCompiler::write(std::string file_name)
{
    std::error_code EC;
    raw_fd_ostream fout(file_name, EC, sys::fs::OF_None);
    WriteBitcodeToFile(module, fout);
    fout.flush();
    fout.close();
}

//  ┌―――――――――――――――――――――┐  //
//  │ AST -> LLVM Codegen │  //
// └―――――――――――――――――――――┘   //

// codegen for statements
Value *NodeStmts::llvm_codegen(LLVMCompiler *compiler)
{
    Value *last = nullptr;
    for (auto node : list)
    {
        last = node->llvm_codegen(compiler);
    }
    return last;
}

Value *NodeDebug::llvm_codegen(LLVMCompiler *compiler)
{
    Value *expr = expression->llvm_codegen(compiler);

    Function *printi_func = compiler->module.getFunction("printi");
    compiler->builder.CreateCall(printi_func, {expr});

    return expr;
}

Value *NodeShort::llvm_codegen(LLVMCompiler *compiler) {
    return compiler->builder.getInt16(value);
}
Value *NodeInt::llvm_codegen(LLVMCompiler *compiler)
{
    return compiler->builder.getInt32(value);
}
Value *NodeLong::llvm_codegen(LLVMCompiler *compiler)
{
    return compiler->builder.getInt64(value);
}

Value *NodeBinOp::llvm_codegen(LLVMCompiler *compiler)
{
    Value *left_expr = left->llvm_codegen(compiler);
    Value *right_expr = right->llvm_codegen(compiler);
    
    switch(op) {
        case PLUS:
        return compiler->builder.CreateAdd(left_expr, right_expr, "addtmp");
    case MINUS:
        return compiler->builder.CreateSub(left_expr, right_expr, "minustmp");
    case MULT:
        return compiler->builder.CreateMul(left_expr, right_expr, "multtmp");
    case DIV:
        return compiler->builder.CreateSDiv(left_expr, right_expr, "divtmp");
    }
}

Value *NodeDecl::llvm_codegen(LLVMCompiler *compiler)
{
    Value *expr = expression->llvm_codegen(compiler);
    IRBuilder<> temp_builder(
        &MAIN_FUNC->getEntryBlock(),
        MAIN_FUNC->getEntryBlock().begin());
    AllocaInst *alloc;
    if (this->dtype == 0)
    {
        alloc = temp_builder.CreateAlloca(compiler->builder.getInt16Ty(), 0, identifier);
    }
    if (this->dtype == 1)
    {
        alloc = temp_builder.CreateAlloca(compiler->builder.getInt32Ty(), 0, identifier);
    }
    else{
        
        alloc = temp_builder.CreateAlloca(compiler->builder.getInt64Ty(), 0, identifier);
   }
    if(scope<=(int)compiler->locals[identifier].size())
        compiler->locals[identifier][scope-1] = alloc;
    else
        compiler->locals[identifier].push_back(alloc);

    return compiler->builder.CreateStore(expr, alloc);
}

Value *NodeIdent::llvm_codegen(LLVMCompiler *compiler)
{
    AllocaInst *alloc = compiler->locals[identifier][scope-1];

    // if your LLVM_MAJOR_VERSION >= 14
    return compiler->builder.CreateLoad(compiler->builder.getInt64Ty(), alloc, identifier);
}

Value *NodeIf::llvm_codegen(LLVMCompiler *compiler)
{
    Value *cond = condition->llvm_codegen(compiler);
    if (!cond)
        return nullptr;

    cond = compiler->builder.CreateICmpSLT(
        compiler->builder.getInt64(0),
        cond,
        "ifcond");

    Function *func = compiler->builder.GetInsertBlock()->getParent();

    BasicBlock *then_bb = BasicBlock::Create(*compiler->context, "then", func);
    BasicBlock *else_bb = BasicBlock::Create(*compiler->context, "else");
    BasicBlock *merge_bb = BasicBlock::Create(*compiler->context, "ifcont");

    compiler->builder.CreateCondBr(cond, then_bb, else_bb);

    compiler->builder.SetInsertPoint(then_bb);

    Value *then_val = if_branch->llvm_codegen(compiler);
    if (!then_val)
        return nullptr;

    StoreInst *store = dyn_cast<StoreInst>(then_val);
    if (store)
        then_val = store->getValueOperand();

    compiler->builder.CreateBr(merge_bb);
    then_bb = compiler->builder.GetInsertBlock();

    func->getBasicBlockList().push_back(else_bb);
    compiler->builder.SetInsertPoint(else_bb);

    Value *else_val = else_branch->llvm_codegen(compiler);
    if (!else_val)
        return nullptr;

    StoreInst *store2 = dyn_cast<StoreInst>(else_val);
    if (store2)
        else_val = store2->getValueOperand();

    compiler->builder.CreateBr(merge_bb);
    else_bb = compiler->builder.GetInsertBlock();

    func->getBasicBlockList().push_back(merge_bb);
    compiler->builder.SetInsertPoint(merge_bb);

    PHINode *phi_node = compiler->builder.CreatePHI(
        compiler->builder.getInt64Ty(),
        2,
        "iftmp");

    phi_node->addIncoming(then_val, then_bb);
    phi_node->addIncoming(else_val, else_bb);

    return phi_node;
}

#undef MAIN_FUNC("using undeclared variable.\n");
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
