#ifndef AST_HH
#define AST_HH

#include <llvm/IR/Value.h>
#include <string>
#include <vector>

struct LLVMCompiler;

/**
Base node class. Defined as `abstract`.
*/
struct Node
{
    enum NodeType
    {
        BIN_OP,
        INT_LIT,
        STMTS,
        ASSN,
        DBG,
        IDENT,
        IF,
        FUNCTION,
        ARG_LIST
    } type;

    int dtype;
    virtual bool isIntLit() const { return false; }
    virtual bool isIdent() const { return false; }
    virtual std::string to_string() = 0;
    virtual llvm::Value *llvm_codegen(LLVMCompiler *compiler) = 0;
    std::string nameOfVariable;
    virtual int get_type();
};

/**
    Node for list of statements
*/
struct NodeStmts : public Node
{
    std::vector<Node *> list;

    NodeStmts();
    void push_back(Node *node);
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
};

/**
    Node for binary operations
*/
struct NodeBinOp : public Node
{
    enum Op
    {
        PLUS,
        MINUS,
        MULT,
        DIV
    } op;

    Node *left, *right;

    NodeBinOp(Op op, Node *leftptr, Node *rightptr);
    std::string to_string();
    int get_type();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
};

/**
    Node for integer literals
*/
struct NodeInt : public Node
{
    long long int value;

    NodeInt(long long int val);
    std::string to_string();
    int getValue() const { return value; }
    virtual bool isIntLit() const { return true; }
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
    int get_type();
};

/**
    Node for variable assignments
*/
struct NodeDecl : public Node
{
    std::string identifier;
    Node *expression;
    NodeDecl(std::string id, int t, Node *expr,int s);
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
    int scope;
};

/**
    Node for `dbg` statements
*/
struct NodeDebug : public Node
{
    Node *expression;

    NodeDebug(Node *expr);
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
};

/**
    Node for idnetifiers
*/
struct NodeIdent : public Node
{
    std::string identifier;

    NodeIdent(std::string ident, int t,int s);
    std::string to_string();
    virtual bool isIdent() const { return true; }
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
    int get_type();
    int scope;
};

/**
    Node for `if` statements
*/
struct NodeIf : public Node
{
    Node *condition;
    NodeStmts *if_branch, *else_branch;

    NodeIf(Node *condition, NodeStmts *if_branch, NodeStmts *else_branch);
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler);
};

struct NodeArgList : public Node
{
    NodeArgList();
    void push_back(NodeDecl *node);
    std::vector<NodeDecl *> list;
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler){return nullptr;};
};
struct NodeFunction : public Node
{
    std::string function_name;
    NodeArgList *arguments;
    int return_type;
    NodeStmts *function_body;

    NodeFunction(std::string name, NodeArgList *args, int ret_type, NodeStmts *body);
    std::string to_string();
    llvm::Value *llvm_codegen(LLVMCompiler *compiler){return nullptr;};
};


#endif