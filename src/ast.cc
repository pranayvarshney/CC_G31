#include "ast.hh"

#include <string>
#include <vector>
#include "symbol.hh"
#include <iostream>

int Node::get_type()
{
    return this->dtype;
}
NodeBinOp::NodeBinOp(NodeBinOp::Op ope, Node *leftptr, Node *rightptr)
{
    type = BIN_OP;
    op = ope;
    left = leftptr;
    right = rightptr;
}

std::string NodeBinOp::to_string()
{
    std::string out = "(";
    switch (op)
    {
    case PLUS:
        out += '+';
        break;
    case MINUS:
        out += '-';
        break;
    case MULT:
        out += '*';
        break;
    case DIV:
        out += '/';
        break;
    }

    out += ' ' + left->to_string() + ' ' + right->to_string() + ')';

    return out;
}
int NodeBinOp::get_type()
{
    int left_type = left->get_type();
    int right_type = right->get_type();

    // Check if types are compatible
    // int  = 1 ; long 2 ; short = 0
    return left_type > right_type ? left_type : right_type;

    // Incompatible types
    return -1;
}
// int NodeInt::get_type()
// {
//     if (value >= -32768 && value <= 32767)
//     {
//         dtype = 0; // short
//     }
//     else if (value >= -2147483648 && value <= 2147483647)
//     {
//         dtype = 1; // int
//     }
//     else
//     {
//         dtype = 2; // long
//     }
//     return dtype;
// }

NodeShort::NodeShort(short val)
{
    type = INT_LIT;
    value = val;
    dtype = 0;
}

std::string NodeShort::to_string()
{
    return std::to_string(value);
}

NodeInt::NodeInt(int val)
{
    type = INT_LIT;
    value = val;
    dtype = 1;
}


std::string NodeInt::to_string()
{
    return std::to_string(value);
}

NodeLong::NodeLong(long long int val)
{
    type = INT_LIT;
    value = val;
    dtype = 2;
}

std::string NodeLong::to_string()
{
    return std::to_string(value);
}

NodeStmts::NodeStmts()
{
    type = STMTS;
    list = std::vector<Node *>();
}

void NodeStmts::push_back(Node *node)
{
    list.push_back(node);
}

std::string NodeStmts::to_string()
{
    std::string out = "(begin";
    for (auto i : list)
    {
        out += " " + i->to_string();
    }

    out += ')';

    return out;
}

NodeDecl::NodeDecl(std::string id, int t, Node *expr,int s)
{
    type = ASSN;
    identifier = id;
    expression = expr;
    dtype = t;
    if (this->dtype < expression->get_type()){
        perror("Type mismatch\n");
        exit(1);
    }
    nameOfVariable = id;
    scope = s;
}
void NodeDecl::set_func_name(std::string se ){
    this->func_name = se;
}
std::string NodeDecl::to_string()
{
    return "(let " + identifier + " " + expression->to_string() + ")";
}

NodeDebug::NodeDebug(Node *expr)
{
    type = DBG;
    expression = expr;
}

std::string NodeDebug::to_string()
{
    return "(dbg " + expression->to_string() + ")";
}

NodeIdent::NodeIdent(std::string ident, int t,int s)
{
    identifier = ident;
    dtype = t;
    scope = s;
}
std::string NodeIdent::to_string()
{
    return identifier;
}
int NodeIdent::get_type()
{
    return this->dtype;
}

NodeIf::NodeIf(Node *conditionptr, NodeStmts *ifbranch, NodeStmts *elsebranch) {
    type = IF;
    condition = conditionptr;
    if_branch = ifbranch;
    else_branch = elsebranch;
}
std::string NodeIf::to_string() {
    std::string out;
    if(if_branch && else_branch)
        out = "(if " + condition->to_string() + " then " + if_branch->to_string() + " else " + else_branch->to_string() + ')';
    else if(else_branch)
        out = "(if " + condition->to_string() + " then else " + else_branch->to_string() + ')';
    else if(if_branch)
        out = "(if " + condition->to_string() + " then " + if_branch->to_string() + " else )";
    else
        out = "(if " + condition->to_string() + " then else )";
    return out;
}

NodeFunction::NodeFunction(std::string name, NodeArgList *args, int ret_type, NodeStmts *body, int s)
{
    type = FUNCTION;
    function_name = name;
    arguments = args;
    return_type = ret_type;
    function_body = body;
    scope = s;
}

std::string NodeFunction::to_string()
{
    std::string out = "(Function " + function_name + "(";
    out+=arguments->to_string();
    out += ") { " + function_body->to_string() + " } )";
    return out;
}

NodeArgList::NodeArgList(){
    type = ARG_LIST;
    list = std::vector<Node *>();
    call = std::vector<Node *>();
}

void NodeArgList::push_back(Node* arg)
{
    list.push_back(arg);
}

void NodeArgList::push_back_call(Node* arg)
{
    call.push_back(arg);
}
std::string NodeArgList::to_string()
{
    std::string out = "(";
    for (auto arg : list)
    {
        out += " "+arg->to_string();
    }
    out += " )";
    return out;
}

NodeFunctionCall::NodeFunctionCall(std::string name, NodeArgList *args, int s)
{
    type = FCALL;
    function_name = name;
    arguments = args;
    scope = s;
}

std::string NodeFunctionCall::to_string()
{
    std::string out = "(Function call " + function_name + "(";
    out+=arguments->to_string();
    out += ")";
    return out;
}