#include "llvmcodegen.hh"
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
        false);
    Function::Create(
        printi_func_type,
        GlobalValue::ExternalLinkage,
        "printi",
        &module);

    FunctionType *printi_func_type1 = FunctionType::get(
        builder.getVoidTy(),
        {builder.getInt32Ty()},
        false);
    Function::Create(
        printi_func_type1,
        GlobalValue::ExternalLinkage,
        "printi2",
        &module);

    FunctionType *printi_func_type2 = FunctionType::get(
        builder.getVoidTy(),
        {builder.getInt16Ty()},
        false);
    Function::Create(
        printi_func_type2,
        GlobalValue::ExternalLinkage,
        "printi3",
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
    // generate code for the root node
    for (auto node : dynamic_cast<NodeStmts *>(root)->list)
    {
        if (node->type == Node::NodeType::FUNCTION && dynamic_cast<NodeFunction *>(node)->function_name == "main")
        {
            // move the builder to the start of the main function block
            builder.SetInsertPoint(main_func_entry_bb);
            node->llvm_codegen(this);
        }
        else
        {
            node->llvm_codegen(this);
        }
    }

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
//  └―――――――――――――――――――――┘   //

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

    // Function *printi_func = compiler->module.getFunction("printi");
    // compiler->builder.CreateCall(printi_func, {expr});
    Function *printi_func;

    if (expr->getType() == compiler->builder.getInt16Ty())
    {
        printi_func = compiler->module.getFunction("printi3");
    }
    else if (expr->getType() == compiler->builder.getInt32Ty())
    {
        printi_func = compiler->module.getFunction("printi2");
    }
    else
    {
        printi_func = compiler->module.getFunction("printi");
    }

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

    Type *ltype = left_expr->getType();
    Type *rtype = right_expr->getType();

    if(ltype->getIntegerBitWidth() < rtype->getIntegerBitWidth()) {
        left_expr = compiler->builder.CreateZExt(left_expr, rtype);
    } else if(ltype->getIntegerBitWidth() > rtype->getIntegerBitWidth()) {
        right_expr = compiler->builder.CreateZExt(right_expr, ltype);
    }
    
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
    Type* expr_type = expr->getType();

    IRBuilder<> temp_builder(
        &MAIN_FUNC->getEntryBlock(),
        MAIN_FUNC->getEntryBlock().begin());
    AllocaInst *alloc;
    if (this->dtype == 0)
    {
        alloc = temp_builder.CreateAlloca(compiler->builder.getInt16Ty(), 0, identifier);
    }
    else if (this->dtype == 1)
    {
        alloc = temp_builder.CreateAlloca(compiler->builder.getInt32Ty(), 0, identifier);
        if (expr_type == compiler->builder.getInt16Ty())
        {
            expr = compiler->builder.CreateSExt(expr, compiler->builder.getInt32Ty());
        }
    }
    else{
        if (expr_type == compiler->builder.getInt32Ty() || expr_type == compiler->builder.getInt16Ty())
        {
            expr = compiler->builder.CreateSExt(expr, compiler->builder.getInt64Ty());
        }

        alloc = temp_builder.CreateAlloca(compiler->builder.getInt64Ty(), 0, identifier);
   }
       

    if (scope <= (int)compiler->locals[identifier].size())
        compiler->locals[identifier][scope - 1] = alloc;
    else
        for (int i = compiler->locals[identifier].size(); i < scope; i++)
            compiler->locals[identifier].push_back(alloc);

    return compiler->builder.CreateStore(expr, alloc);
}

Value *NodeIdent::llvm_codegen(LLVMCompiler *compiler)
{
    std::cout<<"identifier: "<<identifier<<" scope: "<<scope<<" size: "<<compiler->locals[identifier].size()<<std::endl;
    AllocaInst *alloc = compiler->locals[identifier][scope - 1];

    // if your LLVM_MAJOR_VERSION >= 14
    if(this->dtype == 0){
        return compiler->builder.CreateLoad(compiler->builder.getInt16Ty(), alloc, identifier);
    }
    if(this->dtype == 1){
        return compiler->builder.CreateLoad(compiler->builder.getInt32Ty(), alloc, identifier);
    }
    return compiler->builder.CreateLoad(compiler->builder.getInt64Ty(), alloc, identifier);

}

Value *NodeIf::llvm_codegen(LLVMCompiler *compiler)
{
    Value *cond = condition->llvm_codegen(compiler);
    if (!cond)
        return nullptr;
    cond = compiler->builder.CreateIntCast(
        cond,
        compiler->builder.getInt64Ty(),
        true,
        "ifcond");
    cond = compiler->builder.CreateICmpSLT(
        compiler->builder.getInt64(0),
        cond,
        "ifcond");
    // compare condition to 0 of differernt types;
    Function *func = compiler->builder.GetInsertBlock()->getParent();

    BasicBlock *then_bb = BasicBlock::Create(*compiler->context, "then", func);
    BasicBlock *else_bb = BasicBlock::Create(*compiler->context, "else");
    BasicBlock *merge_bb = BasicBlock::Create(*compiler->context, "ifcont");

    compiler->builder.CreateCondBr(cond, then_bb, else_bb);

    compiler->builder.SetInsertPoint(then_bb);

    Value *then_val = if_branch->llvm_codegen(compiler);
    if (!then_val)
    {
        then_val = compiler->builder.getInt64(0);
    }

    StoreInst *store = dyn_cast<StoreInst>(then_val);
    if (store)
        then_val = store->getValueOperand();

    then_val = compiler->builder.CreateIntCast(then_val, compiler->builder.getInt64Ty(), true);

    compiler->builder.CreateBr(merge_bb);
    then_bb = compiler->builder.GetInsertBlock();

    func->getBasicBlockList().push_back(else_bb);
    compiler->builder.SetInsertPoint(else_bb);

    Value *else_val = else_branch->llvm_codegen(compiler);
    if (!else_val)
    {
        else_val = compiler->builder.getInt64(0);
    }

    StoreInst *store2 = dyn_cast<StoreInst>(else_val);
    if (store2)
        else_val = store2->getValueOperand();

    else_val = compiler->builder.CreateIntCast(else_val, compiler->builder.getInt64Ty(), true);

    compiler->builder.CreateBr(merge_bb);
    else_bb = compiler->builder.GetInsertBlock();

    func->getBasicBlockList().push_back(merge_bb);
    compiler->builder.SetInsertPoint(merge_bb);

    PHINode *phi_node = compiler->builder.CreatePHI(
        then_val->getType(),
        2,
        "iftmp");

    phi_node->addIncoming(then_val, then_bb);
    phi_node->addIncoming(else_val, else_bb);

    return phi_node;
}

Type *getIntType(int n, LLVMCompiler *compiler)
{
    switch (n)
    {
    case 0:
        return Type::getInt16Ty(*compiler->context);
    case 1:
        return Type::getInt32Ty(*compiler->context);
    case 2:
        return Type::getInt64Ty(*compiler->context);
    default:
        llvm::errs() << "Invalid return_type: " << n << "\n";
        return nullptr;
    }
}

Value *NodeFunction::llvm_codegen(LLVMCompiler *compiler)
{
    if (function_name == "main")
    {
        function_body->llvm_codegen(compiler);
        return nullptr;
    }
    std::vector<Type *> args_type;

    for (auto arg : arguments->list)
    {
        args_type.push_back(getIntType(arg->dtype, compiler));
    }

    Type *ReturnType = getIntType(return_type, compiler);
    FunctionType *func_type = FunctionType::get(ReturnType, args_type, false);

    Function *func = Function::Create(
        func_type,
        Function::ExternalLinkage,
        function_name,
        compiler->module);

    unsigned Idx = 0;
    for (Function::arg_iterator arg = func->arg_begin(); arg != func->arg_end(); ++arg, ++Idx)
    {
        std::string arg_name = dynamic_cast<NodeIdent *>(arguments->list[Idx])->identifier;
        arg->setName(arg_name);
    }

    BasicBlock *bb = BasicBlock::Create(*compiler->context, "entry", func);
    compiler->builder.SetInsertPoint(bb);
    IRBuilder<> temp_builder(
        &func->getEntryBlock(),
        func->getEntryBlock().begin());
    Idx=0;
    for (Function::arg_iterator arg = func->arg_begin(); arg != func->arg_end(); ++arg, ++Idx)
    {
        std::string identifier = dynamic_cast<NodeIdent *>(arguments->list[Idx])->identifier;
        AllocaInst *alloc = temp_builder.CreateAlloca(getIntType(arguments->list[Idx]->dtype, compiler), 0, identifier);
        if (scope <= (int)compiler->locals[identifier].size())
            compiler->locals[identifier][scope - 1] = alloc;
        else
            for (int i = compiler->locals[identifier].size(); i < scope; i++)
                compiler->locals[identifier].push_back(alloc);
        compiler->builder.CreateStore(func->arg_begin() + Idx, alloc);
    }

    if (Value *ret = function_body->llvm_codegen(compiler))
    {
        compiler->builder.CreateRet(ret);
    }
    else
    {
        switch (return_type)
        {
        case 0:
            compiler->builder.CreateRet(compiler->builder.getInt16(0));
        case 1:
            compiler->builder.CreateRet(compiler->builder.getInt32(0));
        case 2:
            compiler->builder.CreateRet(compiler->builder.getInt64(0));
        default:
            compiler->builder.CreateRet(compiler->builder.getInt64(0));
        }
    }
    return func;
}

Value *NodeFunctionCall::llvm_codegen(LLVMCompiler *compiler){
    Function *func = compiler->module.getFunction(function_name);
    
    std::vector<Value *> args;
    for (auto arg : arguments->call)
    {
        args.push_back(arg->llvm_codegen(compiler));
    }
    std::string call_name = "call_" + function_name;
    Value *ret = compiler->builder.CreateCall(func, args, call_name);
    return ret;
    // return nullptr;
}
#undef MAIN_FUNC