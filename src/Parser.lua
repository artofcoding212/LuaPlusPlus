--NOTE: This is to be parented under the "luapp.lua" file.

--// Variables //--

local Lexer = require(script.Parent.Lexer)
local Ast = require(script.Parent.Ast)

--// Types //--

export type Parser={
    Result: Ast.Program;
    tokens: {Lexer.Token};
    
    Parse: (tokens: {Lexer.Token})->Ast.Program,
    
    ParseStmt: ()->Ast.Stmt,
    ParseClassDeclarationStmt: ()->Ast.Stmt,
    ParseForStmt: ()->Ast.Stmt,
    ParseWhileStmt: ()->Ast.Stmt;
    ParseIfStmt: ()->Ast.Stmt;
    ParseReturnStmt: ()->Ast.Stmt;
    ParseBreakStmt: ()->Ast.Stmt;
    ParseContinueStmt: ()->Ast.Stmt;
    ParseFunctionDeclarationStmt: (class: boolean?)->Ast.Stmt;
    ParseVariableDeclarationStmt: ()->Ast.Stmt;
    ParseSwitchStmt: ()->Ast.Stmt;
    
    ParseExpr: ()->Ast.Expr;
    ParseNewExpr: ()->Ast.Expr;
    ParsePostfixUnaryExpr: ()->Ast.Expr;
    ParseAssignmentExpr: ()->Ast.Expr;
    ParseOrExpr: ()->Ast.Expr;
    ParseAndExpr: ()->Ast.Expr;
    ParseEqualityExpr: ()->Ast.Expr;
    ParseComparisonExpr: ()->Ast.Expr;
    ParseObjectExpr: ()->Ast.Expr;
    ParseArrayExpr: ()->Ast.Expr;
    ParseTermExpr: ()->Ast.Expr;
    ParseFactorExpr: ()->Ast.Expr;
    ParsePowerExpr: ()->Ast.Expr;
    ParsePrefixUnaryExpr: ()->Ast.Expr;
    ParseCallMemberExpr: ()->Ast.Expr;
    ParseMemberExpr: ()->Ast.Expr;
    ParseCallExpr: (caller: Ast.Expr)->Ast.Expr;
    ParseArguments: ()->{Ast.Expr};
    ParseArgumentList: ()->{Ast.Expr};
    ParsePrimaryExpr: ()->Ast.Expr;
}

--// Module //--

local parser: Parser={
    Result={Kind="program"::Ast.NodeType, Body={}},
    tokens={},
}

function parser.Parse(tokens)
    parser.tokens = tokens
    
    local program: Ast.Program = {Kind="program"::Ast.NodeType, Body={}}::Ast.Program
    
    while parser.tokens[1].Type ~= "eof" do
        table.insert(program.Body, parser.ParseStmt())
    end
    
    parser.Result = program
    return program
end

function parser.ParseStmt()
    local switch: {[Lexer.TokenType]: ()->Ast.Stmt}={
        ["class"]=parser.ParseClassDeclarationStmt,
        ["for"]=parser.ParseForStmt,
        ["while"]=parser.ParseWhileStmt,
        ["if"]=parser.ParseIfStmt,
        ["return"]=parser.ParseReturnStmt,
        ["break"]=parser.ParseBreakStmt,
        ["continue"]=parser.ParseContinueStmt,
        ["func"]=parser.ParseFunctionDeclarationStmt,
        ["var"]=parser.ParseVariableDeclarationStmt,
        ["switch"]=parser.ParseSwitchStmt,
    }
    
    if switch[parser.tokens[1].Type] then
        local statement: Ast.Stmt = switch[parser.tokens[1].Type]()
        
        if parser.tokens[1].Type == "semicolon" then
            table.remove(parser.tokens, 1)
        end
        
        return statement
    else
        local expression = {Kind="expression_statement"::Ast.NodeType, Value=parser.ParseExpr()}::Ast.ExprStmt
        
        if parser.tokens[1].Type == "semicolon" then
            table.remove(parser.tokens, 1)
        end
    
        return expression
    end
end

function parser.ParseClassDeclarationStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "identifier" then
        error("Lua++/Parser -> Expected a class name following the \"class\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    local name: Ast.Identifier={Kind="identifier"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Value}
    local variables: {Ast.ClassVariable}={}
    local methods: {Ast.ClassMethod}={}
    local initializer: Ast.ClassMethod? = nil
    
    if parser.tokens[1].Type ~= "open_brace" then
        error("Lua++/Parser -> Expected an open brace following a class name whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        if parser.tokens[1].Type == "func" then
            local method = parser.ParseFunctionDeclarationStmt(true)::Ast.ClassMethod
            
            if method.Name.Kind == "identifier" and (method.Name::Ast.Identifier).Value == name.Value then
                if initializer ~= nil then
                    error("Lua++/Parser -> Encountered a second class initalizer whilst parsing.")
                end
                
                initializer = method
            else
                table.insert(methods, method)
            end
            
            if parser.tokens[1].Type == "semicolon" then
                table.remove(parser.tokens, 1)
            end
        elseif parser.tokens[1].Type == "var" then
            local variable: Ast.ClassVariable = parser.ParseVariableDeclarationStmt()::Ast.ClassVariable
            variable.Kind = "class_variable"

            table.insert(variables, variable)
            
            if parser.tokens[1].Type == "semicolon" then
                table.remove(parser.tokens, 1)
            end
        else
            error("Lua++/Parser -> Expected either the \"func\" keyword or the \"var\" keyword whilst parsing a variable declaration, instead got a \""..parser.tokens[1].Type.."\"")
        end
    end
    
    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace following a class body whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)

    return {Kind="class_declaration"::Ast.NodeType, Name=name, Initializer=initializer, Variables=variables, Methods=methods}::Ast.ClassDeclaration
end

function parser.ParseForStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_paren" then
        error("Lua++/Parser -> Expected an open parenthesis following the \"for\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local variables: {Ast.Identifier}={}
    local iterator: Ast.Expr={}
    
    if parser.tokens[1].Type ~= "identifier" then
        error("Lua++/Parser -> Expected at least one for loop variable whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    while parser.tokens[1].Type == "identifier" do
        table.insert(variables, {Kind="identifier"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Value}::Ast.Identifier)
        
        if parser.tokens[1].Type ~= "comma" then
            break
        else
            table.remove(parser.tokens, 1)
        end
    end
    
    if parser.tokens[1].Type ~= "in" then
        error("Lua++/Parser -> Expected the \"in\" keyword following the for loop variable declarations whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    iterator = parser.ParseExpr()
    
    if parser.tokens[1].Type ~= "close_paren" then
        error("Lua++/Parser -> Expected a closing parenthesis following the for loop data whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_brace" then
        error("Lua++/Parser -> Expected an open brace following the for loop data whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local body: {Ast.Stmt}={}
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        table.insert(body, parser.ParseStmt())
    end
    
    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace following the for loop body whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    return {Kind="for"::Ast.NodeType, Variables=variables, Iterator=iterator, Body=body}::Ast.For
end

function parser.ParseWhileStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_paren" then
        error("Lua++/Parser -> Expected an open parenthesis following the \"while\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local condition = parser.ParseExpr()
    
    if parser.tokens[1].Type ~= "close_paren" then
        error("Lua++/Parser -> Expected a closing parenthesis following the while loop condition whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)

    if parser.tokens[1].Type ~= "open_brace" then
        error("Lua++/Parser -> Expected an open brace following the while loop condition whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)

    local body: {Ast.Stmt}={}

    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        table.insert(body, parser.ParseStmt())
    end

    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace following the while loop body whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)
    return {Kind="while"::Ast.NodeType, Condition=condition, Body=body}::Ast.While
end

function parser.ParseIfStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_paren" then
        error("Lua++/Parser -> Expected an open parenthesis following the \"for\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local condition = parser.ParseExpr()
    
    if parser.tokens[1].Type ~= "close_paren" then
        error("Lua++/Parser -> Expected a closing parenthesis following the if branch condition, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_brace" then
        error("Lua++/Parser -> Expected an open brace following the if branch condition whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)

    local thenBody: {Ast.Stmt}={}

    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        table.insert(thenBody, parser.ParseStmt())
    end

    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace following the if branch body whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type == "else" then
        table.remove(parser.tokens, 1)
        
        if parser.tokens[1].Type == "open_brace" then
            if parser.tokens[1].Type ~= "open_brace" then
                error("Lua++/Parser -> Expected an open brace following the else branch condition whilst parsing an if statement, instead got a \""..parser.tokens[1].Type.."\".")
            end

            table.remove(parser.tokens, 1)

            local elseBody: {Ast.Stmt}={}

            while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
                table.insert(elseBody, parser.ParseStmt())
            end

            if parser.tokens[1].Type ~= "close_brace" then
                error("Lua++/Parser -> Expected a closing brace following the else branch body whilst parsing an if statement, instead got a \""..parser.tokens[1].Type.."\".")
            end

            table.remove(parser.tokens, 1)
            return {Kind="if"::Ast.NodeType, Condition=condition, ThenBody=thenBody, ElseBody=elseBody}::Ast.If
        elseif parser.tokens[1].Type == "if" then
            return {Kind="if"::Ast.NodeType, Condition=condition, ThenBody=thenBody, ElseBody=parser.ParseIfStmt()}::Ast.If
        else
            error("Lua++/Parser -> Expected an open brace or the \"if\" keyword following the \"else\" keyword whilst parsing an if statement, instead got a \""..parser.tokens[1].Type.."\".")
        end
    else
        return {Kind="if"::Ast.NodeType, Condition=condition, ThenBody=thenBody, ElseBody=nil}::Ast.If
    end
end

function parser.ParseReturnStmt()
    table.remove(parser.tokens, 1)
    
    return {Kind="return"::Ast.NodeType, Value=parser.ParseExpr()}::Ast.Return
end

function parser.ParseBreakStmt()
    table.remove(parser.tokens, 1)

    return {Kind="break"::Ast.NodeType}::Ast.Break
end

function parser.ParseContinueStmt()
    table.remove(parser.tokens, 1)

    return {Kind="continue"::Ast.NodeType}::Ast.Continue
end

function parser.ParseFunctionDeclarationStmt(class)
    table.remove(parser.tokens, 1)
    
    if class then
        local name: Expr = parser.ParseMemberExpr()
        local parameters: {Ast.Identifier} = parser.ParseArguments()
        
        for _, parameter in parameters do
            if parameter.Kind ~= "identifier" then
                error("Lua++/Parser -> Expected the function parameter name \""..parameter.Value.."\" to be an identifier whilst parsing a function declaration, instead got a \""..parameter.Kind.."\".")
            end
        end
        
        if parser.tokens[1].Type ~= "open_brace" then
            error("Lua++/Parser -> Expected an open brace following the function parameters whilst parsing a function declaration, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)

        local body: {Ast.Stmt}={}

        while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
            local statement: Ast.Stmt = parser.ParseStmt()
            
            table.insert(body, statement)
        end

        if parser.tokens[1].Type ~= "close_brace" then
            error("Lua++/Parser -> Expected a closing brace following the function body whilst parsing a function declaration, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)
        
        return {Kind="class_method"::Ast.NodeType, Body=body, Parameters=parameters, Name=name}::Ast.ClassMethod
    else
        local name: Expr? = parser.tokens[1].Type ~= "open_paren" and parser.ParseMemberExpr() or nil
        local parameters: {Ast.Identifier} = parser.ParseArguments()

        for _, parameter in parameters do
            if parameter.Kind ~= "identifier" then
                error("Lua++/Parser -> Expected the function parameter name \""..parameter.Value.."\" to be an identifier whilst parsing a function declaration, instead got a \""..parameter.Kind.."\".")
            end
        end

        if parser.tokens[1].Type ~= "open_brace" then
            error("Lua++/Parser -> Expected an open brace following the function parameters whilst parsing a function declaration, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)

        local body: {Ast.Stmt}={}

        while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
            table.insert(body, parser.ParseStmt())
        end

        if parser.tokens[1].Type ~= "close_brace" then
            error("Lua++/Parser -> Expected a closing brace following the function body whilst parsing a function declaration, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)

        return {Kind="function_declaration"::Ast.NodeType, Body=body, Parameters=parameters, Name=name}::Ast.FunctionDeclaration
    end
end

function parser.ParseVariableDeclarationStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "identifier" then
        error("Lua++/Parser -> Expected an identifier following the \"var\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    local name: Ast.Identifier = {Kind="identifier"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Value}::Ast.Identifier
    local value: Ast.Expr? = nil
    
    if parser.tokens[1].Type == "assignment" then
        table.remove(parser.tokens, 1)
        value = parser.ParseExpr()
    end
    
    return {Kind="variable_declaration"::Ast.NodeType, Name=name, Value=value}::Ast.VariableDeclaration
end

function parser.ParseSwitchStmt()
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_paren" then
        error("Lua++/Parser -> Expected an open parenthesis following the \"switch\" keyword whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local switcher: Ast.Expr = parser.ParseExpr()
    
    if parser.tokens[1].Type ~= "close_paren" then
        error("Lua++/Parser -> Expected a closing parenthesis following the switcher whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    if parser.tokens[1].Type ~= "open_brace" then
        error("Lua++/Parser -> Expected an open brace following the switcher whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)

    local cases: {[Ast.Expr]: {Ast.Stmt}}={}
    local default: {Ast.Stmt}? = nil
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        if parser.tokens[1].Type == "default" then
            if default ~= nil then
                error("Lua++/Parser -> Encountered a second default case whilst parsing a switch statement.")
            end
            
            table.remove(parser.tokens, 1)

            if parser.tokens[1].Type ~= "open_brace" then
                error("Lua++/Parser -> Expected an open brace following the default case whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
            end

            table.remove(parser.tokens, 1)

            local body: {Ast.Stmt}={}

            while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
                table.insert(body, parser.ParseStmt())
            end

            if parser.tokens[1].Type ~= "close_brace" then
                error("Lua++/Parser -> Expected a closing brace following the default case body whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
            end

            table.remove(parser.tokens, 1)
            default = body
            
            continue
        end
        
        local expression = parser.ParseExpr()
        
        if cases[expression] then
            error("Lua++/Parser -> Encountered a duplicate case whilst parsing a switch statement.")
        end

        if parser.tokens[1].Type ~= "open_brace" then
            error("Lua++/Parser -> Expected an open brace following the case whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)

        local body: {Ast.Stmt}={}

        while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
            table.insert(body, parser.ParseStmt())
        end

        if parser.tokens[1].Type ~= "close_brace" then
            error("Lua++/Parser -> Expected a closing brace following the case body whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
        end

        table.remove(parser.tokens, 1)
        cases[expression] = body
    end

    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace following the switch body whilst parsing a switch statement, instead got a \""..parser.tokens[1].Type.."\".")
    end

    table.remove(parser.tokens, 1)
    return {Kind="switch"::Ast.NodeType, Cases=cases, Default=default}::Ast.Switch
end

function parser.ParseExpr()
    return parser.ParsePostfixUnaryExpr()
end

function parser.ParsePostfixUnaryExpr()
    local left = parser.ParseAssignmentExpr()
    
    if parser.tokens[1].Type == "plus_plus" or parser.tokens[1].Type == "minus_minus" then
        local operator: Lexer.Token = table.remove(parser.tokens, 1)

        return {Kind="binary"::Ast.NodeType, Right={Kind="identifier"::Ast.NodeType, Value=operator.Value}::Ast.Identifier, Operator=operator, Left=left}::Ast.Binary
    end
    
    return left
end

function parser.ParseAssignmentExpr()
    local left = parser.ParseOrExpr()
    
    if parser.tokens[1].Type == "assignment" or parser.tokens[1].Type == "plus_equals" or parser.tokens[1].Type == "minus_equals" or parser.tokens[1].Type == "slash_equals" or parser.tokens[1].Type == "percent_equals" or parser.tokens[1].Type == "star_equals" or parser.tokens[1].Type == "star_star_equals" then
        return {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseExpr()}::Ast.Binary
    end
    
    return left
end

function parser.ParseOrExpr()
    local left = parser.ParseAndExpr()
    
    while parser.tokens[1].Type == "or" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseAndExpr()}::Ast.Binary
    end
    
    return left
end

function parser.ParseAndExpr()
    local left = parser.ParseEqualityExpr()

    while parser.tokens[1].Type == "and" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseEqualityExpr()}::Ast.Binary
    end

    return left
end

function parser.ParseEqualityExpr()
    local left = parser.ParseComparisonExpr()

    while parser.tokens[1].Type == "equals" or parser.tokens[1].Type == "bang_equals" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseComparisonExpr()}::Ast.Binary
    end

    return left
end

function parser.ParseComparisonExpr()
    local left = parser.ParseObjectExpr()

    while parser.tokens[1].Type == "greater_equals" or parser.tokens[1].Type == "greater" or parser.tokens[1].Type == "less_equals" or parser.tokens[1].Type == "less" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseObjectExpr()}::Ast.Binary
    end

    return left
end

function parser.ParseObjectExpr()
    if parser.tokens[1].Type ~= "open_brace" then
        return parser.ParseArrayExpr()
    end
    
    table.remove(parser.tokens, 1)
    
    local properties: {{Key: Ast.Expr, Value: Ast.Expr?}}={}
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_brace" do
        local key = parser.ParseExpr()
        
        if parser.tokens[1].Type == "comma" then
            table.remove(parser.tokens, 1)
            table.insert(properties, {Key=key, Value=nil})
        elseif parser.tokens[1].Type == "close_brace" then
            table.insert(properties, {Key=key, Value=nil})
        elseif parser.tokens[1].Type == "colon" then
            table.remove(parser.tokens, 1)
            table.insert(properties, {Key=key, Value=parser.ParseExpr()})
            
            if parser.tokens[1].Type ~= "close_brace" then
                if parser.tokens[1].Type ~= "comma" then
                    error("Lua++/Parser -> Expected a closing brace or a comma following an object property whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
                end
                
                table.remove(parser.tokens, 1)
            end
        else
            error("Lua++/Parser -> Expected a comma, closing brace, or a colon after an object key whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
        end
    end
    
    if parser.tokens[1].Type ~= "close_brace" then
        error("Lua++/Parser -> Expected a closing brace at the end of an object expression whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    return {Kind="object"::Ast.NodeType, Properties=properties}::Ast.Object
end

function parser.ParseArrayExpr()
    if parser.tokens[1].Type ~= "open_bracket" then
        return parser.ParseTermExpr()
    end
    
    table.remove(parser.tokens, 1)
    
    local properties: {{Index: number, Value: Expr}}={}
    local index: number = 0
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type ~= "close_bracket" do
        local value: Ast.Expr = parser.ParseExpr()
        
        if parser.tokens[1].Type == "comma" then
            table.remove(parser.tokens, 1)
            table.insert(properties, {Index=index, Value=value})
        elseif parser.tokens[1].Type == "close_bracket" then
            table.insert(properties, {Index=index, Value=value})
        else
            error("Lua++/Parser -> Expected a comma or a closing bracket after an array value whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
        end
        
        index += 1
    end
    
    if parser.tokens[1].Type ~= "close_bracket" then
        error("Lua++/Parser -> Expected a closing bracket after the end of an array expression whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    return {Kind="array"::Ast.NodeType, Properties=properties}::Ast.Array
end

function parser.ParseTermExpr()
    local left = parser.ParseFactorExpr()

    while parser.tokens[1].Type == "plus" or parser.tokens[1].Type == "minus" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParseFactorExpr()}::Ast.Binary
    end

    return left
end

function parser.ParseFactorExpr()
    local left = parser.ParsePowerExpr()

    while parser.tokens[1].Type == "slash" or parser.tokens[1].Type == "star" or parser.tokens[1].Type == "percent" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParsePowerExpr()}::Ast.Binary
    end

    return left
end

function parser.ParsePowerExpr()
    local left = parser.ParsePrefixUnaryExpr()

    while parser.tokens[1].Type == "star_star" do
        left = {Kind="binary"::Ast.NodeType, Left=left, Operator=table.remove(parser.tokens, 1), Right=parser.ParsePrefixUnaryExpr()}::Ast.Binary
    end

    return left
end

function parser.ParsePrefixUnaryExpr()
    if parser.tokens[1].Type == "bang" or parser.tokens[1].Type == "minus" then
        local operator: Lexer.Token = table.remove(parser.tokens, 1)
        
        return {Kind="binary"::Ast.NodeType, Left={Kind="identifier"::Ast.NodeType, Value=operator.Value}::Ast.Identifier, Operator=operator, Right=parser.ParsePrefixUnaryExpr()}::Ast.Binary
    end
    
    return parser.ParseCallMemberExpr()
end

function parser.ParseCallMemberExpr()
    local member = parser.ParseMemberExpr()
    
    if parser.tokens[1].Type == "open_paren" then
        return parser.ParseCallExpr(member)
    end
    
    return member
end

function parser.ParseMemberExpr()
    local object = parser.ParseNewExpr()
    
    while parser.tokens[1].Type == "dot" or parser.tokens[1].Type == "open_bracket" do
        local operator: Lexer.Token = table.remove(parser.tokens, 1)
        local property: Ast.Expr
        local computed: boolean = false
        
        if operator.Type == "dot" then
            property = parser.ParsePrimaryExpr()
            
            if property.Kind ~= "identifier" then
                error("Lua++/Parser -> Expected the expression following a noncomputed member expression to be an identifier whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
            end
        elseif operator.Type == "open_bracket" then
            computed = true
            property = parser.ParseExpr()
            
            if parser.tokens[1].Type ~= "close_bracket" then
                error("Lua++/Parser -> Expected a closing bracket following a computed member expression whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
            end
            
            table.remove(parser.tokens, 1)
        else
            error("Lua++/Parser -> Expected an open bracket or a period to follow a member whilst parsing a member expression, instead got a \""..parser.tokens[1].Type.."\".")
        end
        
        object = {Kind="member"::Ast.NodeType, Object=object, Property=property, Computed=computed}::Ast.Member
    end
    
    return object
end

function parser.ParseCallExpr(caller)
    local expression: Ast.Expr={Kind="call"::Ast.NodeType, Caller=caller, Arguments=parser.ParseArguments()}::Ast.Call
    
    if parser.tokens[1].Type == "open_paren" then
        expression = parser.ParseCallExpr(expression)
    end
    
    return expression
end

function parser.ParseArguments()
    if parser.tokens[1].Type ~= "open_paren" then
        error("Lua++/Parser -> Expected an open parenthesis whilst parsing an argument list, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    
    local arguments: {Ast.Expr} = parser.tokens[1].Type == "close_paren" and {} or parser.ParseArgumentList()
    
    if parser.tokens[1].Type ~= "close_paren" then
        error("Lua++/Parser -> Expected a closing parenthesis at the end of an argument list whilst parsing, instead got a \""..parser.tokens[1].Type.."\".")
    end
    
    table.remove(parser.tokens, 1)
    return arguments
end

function parser.ParseArgumentList()
    local arguments: {Ast.Expr}={parser.ParseExpr()}
    
    while parser.tokens[1].Type ~= "eof" and parser.tokens[1].Type == "comma" do
        table.remove(parser.tokens, 1)
        table.insert(arguments, parser.ParseExpr())
    end
    
    return arguments
end

function parser.ParseNewExpr()
    if parser.tokens[1].Type ~= "new" then
        return parser.ParsePrimaryExpr()
    end

    table.remove(parser.tokens, 1)
 
    return {Kind="new"::Ast.NodeType, Name=parser.ParseMemberExpr(), Parameters=parser.ParseArguments()}::Ast.New
end

function parser.ParsePrimaryExpr()
    local cases: {[Lexer.TokenType]: ()->Ast.Expr}={
        ["open_paren"]=function()
            table.remove(parser.tokens, 1)
            
            local value = parser.ParseExpr()
            
            if parser.tokens[1].Type ~= "close_paren" then
                error("Lua++/Parser -> Expected a closing parenthesis following a grouping expression, instead got a \""..parser.tokens[1].Type.."\".")
            end
            
            table.remove(parser.tokens, 1)
            return value
        end,
        ["string"]=function() return {Kind="string"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Value}::Ast.String end,
        ["identifier"]=function() return {Kind="identifier"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Value}::Ast.Identifier end,
        ["number"]=function() return {Kind="number"::Ast.NodeType, Value=tonumber(table.remove(parser.tokens, 1).Value)}::Ast.Number end,
        ["true"]=function() return {Kind="boolean"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Type == "true"}::Ast.Boolean end,
        ["false"]=function() return {Kind="boolean"::Ast.NodeType, Value=table.remove(parser.tokens, 1).Type == "true"}::Ast.Boolean end,
        ["nil"]=function() table.remove(parser.tokens, 1) return {Kind="nil"::Ast.NodeType, Value=nil}::Ast.Nil end,
        ["open_brace"]=function() return parser.ParseObjectExpr() end,
        ["open_bracket"]=function() return parser.ParseArrayExpr() end,
    }
    
    if cases[parser.tokens[1].Type] then
        return cases[parser.tokens[1].Type]()
    else
        error("Lua++/Parser -> The token \""..parser.tokens[1].Type.."\" was not parsed.")
    end
end

return parser