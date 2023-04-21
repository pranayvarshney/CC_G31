#include "ast.hh"

#include <iostream>
#include <string>
#include <vector>

NodeBinOp::NodeBinOp(NodeBinOp::Op ope, Node *leftptr, Node *rightptr) {
    type = BIN_OP;
    op = ope;
    left = leftptr;
    right = rightptr;
}

std::string NodeBinOp::to_string() {
    std::string out = "(";
    switch(op) {
        case PLUS: out += '+'; break;
        case MINUS: out += '-'; break;
        case MULT: out += '*'; break;
        case DIV: out += '/'; break;
    }

    out += ' ' + left->to_string() + ' ' + right->to_string() + ')';

    return out;
}

NodeTernary::NodeTernary(Node *conditionptr, Node *leftptr, Node *rightptr) {
    type = TERNARY;
    condition = conditionptr;
    left = leftptr;
    right = rightptr;
}

std::string NodeTernary::to_string() {
    std::string out = "(?: " + condition->to_string() + ' ' + left->to_string() + ' ' + right->to_string() + ')';
    return out;
}

NodeIf::NodeIf(Node *conditionptr, NodeStmts *ifbranch, NodeStmts *elsebranch) {
    type = IF;
    condition = conditionptr;
    if_branch = ifbranch;
    else_branch = elsebranch;
}
std::string NodeIf::to_string() {
    std::string out = "(if " + condition->to_string() + " then "+ if_branch->to_string() + " else " + else_branch->to_string() + ')';
    return out;
}

NodeInt::NodeInt(int val) {
    type = INT_LIT;
    value = val;
}

std::string NodeInt::to_string() {
    return std::to_string(value);
}

NodeStmts::NodeStmts() {
    type = STMTS;
    list = std::vector<Node*>();
}

void NodeStmts::push_back(Node *node) {
    list.push_back(node);
}

std::string NodeStmts::to_string() {
    std::string out = "(begin";
    for(auto i : list) {
        out += " " + i->to_string();
    }

    out += ')';

    return out;
}

NodeDecl::NodeDecl(NodeType AssignType, std::string id, Node *expr) {
    type = AssignType;
    identifier = id;
    expression = expr;
}

std::string NodeDecl::to_string() {
    if(type == ASSN)
        return "(let " + identifier + " " + expression->to_string() + ")";
    else if(type == REASSN)
        return "(assign " + identifier + " " + expression->to_string() + ")";
}

NodeDebug::NodeDebug(Node *expr) {
    type = DBG;
    expression = expr;
}

std::string NodeDebug::to_string() {
    return "(dbg " + expression->to_string() + ")";
}

NodeIdent::NodeIdent(std::string ident) {
    identifier = ident;
}
std::string NodeIdent::to_string() {
    return identifier;
}