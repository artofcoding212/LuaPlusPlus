--NOTE: This file is designed to be parented under the "luapp.lua" file.

--// Variables //--

local Lexer = require(script.Parent.Lexer)

--// Types //--

export type NodeType=
    --EXPRESSIONS
    "number" |
    "boolean" |
    "nil" |
    "string" |
    "identifier" |
    "binary" |
    "member" |
    "array" |
    "object" |
    "call" |
    "new" |
    "expression_statement" |
    --STATEMENTS
    "program" |
    "return" |
    "variable_declaration" |
    "function_declaration" |
    "type_declaration" | --TODO!!!!
    "class_declaration" |
    "class_method" |
    "class_variable" |
    "if" |
    "while" |
    "for" |
    "export" | --TODO!!!!!!
    "switch" |
    "break" | 
    "continue"

export type Stmt={
    Kind: NodeType;
}

export type ExprStmt=Stmt&{
    Value: Expr;
}

export type Program=Stmt&{
    Body: {Stmt};
}

export type For=Stmt&{
    Variables: {Expr};
    Iterator: {Expr};
    Body: {Stmt},
    In: boolean,
}

export type While=Stmt&{
    Condition: Expr;
    Body: {Stmt};
}

export type If=Stmt&{
    Condition: Expr;
    ThenBody: {Stmt};
    ElseBody: ({Stmt} | If)?;
}

export type Return=Stmt&{
    Value: Expr
}

export type Break = Stmt
export type Continue = Stmt

export type TypeDeclaration=Stmt&{
    --TODO!!!!
}

export type FunctionDeclaration=Stmt&{
    Parameters: {Identifier},
    Name: Expr?,
    Body: {Stmt},
}

export type ClassVariable=Stmt&{
    Name: Identifier;
    Value: Expr?;
}

export type ClassMethod=Stmt&{
    Parameters: {Identifier},
    Name: Expr,
    Body: {Stmt},
}

export type ClassDeclaration=Stmt&{
    Name: Identifier;
    Initializer: ClassMethod?;
    Variables: {ClassVariable};
    Methods: {ClassMethod};
}

export type VariableDeclaration=Stmt&{
    Name: Identifier;
    Value: Expr?;
}

export type Switch=Stmt&{
    Switcher: Expr;
    Cases: {[Expr]: {Stmt}};
    Default: {Stmt}?;
}

export type Export=Stmt&{
    --TODO!!!!!
}

export type Expr={
    Kind: NodeType;    
}

export type Boolean=Expr&{
    Value: boolean;
}

export type String=Expr&{
    Value: string;
}

export type Nil=Expr&{
    Value: nil;
}

export type Identifier=Expr&{
    Value: string;
}

export type Number=Expr&{
    Value: number;
}

export type New=Expr&{
    Name: Expr;
    Parameters: {Expr};
}

export type Binary=Expr&{
    Left: Expr;
    Right: Expr;
    Operator: Lexer.Token;
}

export type Call=Expr&{
    Arguments: {Expr};
    Caller: Expr;
}

export type Member=Expr&{
    Object: Expr;
    Property: Expr;
    Computed: boolean;
    Colon: boolean;
}

export type Object=Expr&{
    Properties: {{Key: Expr, Value: Expr?}};
}

export type Array=Expr&{
    Properties: {{Index: number, Value: Expr}};
}

--// Module //--

return {}