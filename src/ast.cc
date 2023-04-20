#include "ast.hh"

#include <string>
#include <vector>
#include "symbol.hh"

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
int NodeInt::get_type()
{
    if (value >= -32768 && value <= 32767)
    {
        dtype = 0; // short
    }
    else if (value >= -2147483648 && value <= 2147483647)
    {
        dtype = 1; // int
    }
    else
    {
        dtype = 2; // long
    }
    return dtype;
}


NodeInt::NodeInt(long long int val)
{
    type = INT_LIT;
    value = val;
}

std::string NodeInt::to_string()
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

NodeDecl::NodeDecl(std::string id, int t, Node *expr)
{
    type = ASSN;
    dtype = t;
    identifier = id;
    expression = expr;
    if (this->dtype < expression->get_type()){
        perror("Type mismatch\n");
        exit(1);
    }
    nameOfVariable = id;
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

NodeIdent::NodeIdent(std::string ident, int t)
{
    identifier = ident;
    dtype = t;
}
std::string NodeIdent::to_string()
{
    return identifier;
}
int NodeIdent::get_type()
{
    return this->dtype;
}