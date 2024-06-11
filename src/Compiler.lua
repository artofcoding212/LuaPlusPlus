--NOTE: This file is designed to be parented under the "luapp.lua" file.

--// Variables //--

local Ast = require(script.Parent.Ast)

--// Types //--

export type Compiler={
    FunctionOverrides: {[string]: (compiler: Compiler, node: Ast.Call)->string};
    nodes: {Ast.Stmt};
    switches: number;

    Compile: (nodes: {Ast.Stmt}, indent: number?, ignoreLine: boolean?)->string;

    CompileForStmt: (node: Ast.For, indent: number)->string;
    CompileWhileStmt: (node: Ast.While, indent: number)->string;
    CompileIfStmt: (node: Ast.If, indent: number)->string;
    CompileFunctionDeclarationStmt: (node: Ast.FunctionDeclaration, indent: number)->string;
    CompileClassDeclarationStmt: (node: Ast.ClassDeclaration, indent: number)->string;
    CompileSwitchStmt: (node: Ast.Switch, indent: number)->string;

    CompileExprStmt: (node: Ast.ExprStmt, indent: number?)->string;
    CompileNewExpr: (node: Ast.New, indent: number)->string;
    CompileBinaryExpr: (node: Ast.Binary, indent: number)->string;
    CompileMemberExpr: (node: Ast.Member, indent: number)->string;
    CompileCallExpr: (node: Ast.Call, indent: number)->string;
    CompileObjectExpr: (node: Ast.Object, indent: number)->string;
    CompileArrayExpr: (node: Ast.Array, indent: number)->string;
}

--// Module //--

local compiler: Compiler={
    FunctionOverrides={
        ["len"]=function(this, node)
            assert(#node.Arguments == 1, "Lua++/Compiler -> Expected 1 argument to the \"len\" function whilst compiling.")
            return "#"..this.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Arguments[1]}::Ast.ExprStmt)
        end,
    },
    nodes={},
    switches=0,
}

function compiler.Compile(nodes, indent, ignoreLine)
    local result: string = ""
    compiler.nodes = nodes

    for _, node in nodes do 
        local switch: {[Ast.NodeType]: (node: Ast.Stmt, indent: number)->string}={
            ["for"]=compiler.CompileForStmt,
            ["while"]=compiler.CompileWhileStmt,
            ["if"]=compiler.CompileIfStmt,
            ["function_declaration"]=compiler.CompileFunctionDeclarationStmt,
            ["class_declaration"]=compiler.CompileClassDeclarationStmt,
            ["variable_declaration"]=compiler.CompileVariableDeclarationStmt,
            ["switch"]=compiler.CompileSwitchStmt,
            ["expression_statement"]=compiler.CompileExprStmt,
            ["return"]=function(node: Ast.Return, indent: number) return "return "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Value}::Ast.ExprStmt) end,
            ["break"]=function(node: Ast.Break, indent: number) return "break" end,
            ["continue"]=function(node: Ast.Continue, indent: number) return "continue" end,
            ["variable_declaration"::Ast.NodeType]=function(node: Ast.VariableDeclaration, indent: number)
                return "local "..node.Name.Value..(node.Value == nil and "" or " = "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Value}::Ast.ExprStmt))
            end,
        }

        if switch[node.Kind] then
            if ignoreLine then
                result = ((indent or 0) > 0 and string.rep("\t", indent) or "")..result..switch[node.Kind](node, indent or 0)
            else
                result = ((indent or 0) > 0 and string.rep("\t", indent) or "")..result..switch[node.Kind](node, indent or 0).."\n"
            end
        else
            error("Lua++/Compiler -> The node \""..node.Kind.."\" was not compiled.")
        end
    end

    return result
end

function compiler.CompileForStmt(node, indent)
    local result = "for "

    for index, variable in node.Variables do
        result = result..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=variable}::Ast.ExprStmt)..(#node.Variables ~= index and ", " or "")
    end
    
    if #node.Iterator > 0 then
        result = result.." in "
        
        for index, iterator in node.Iterator do
            result = result..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=iterator}::Ast.ExprStmt)..(#node.Iterator ~= index and ", " or "")
        end
    end

    return result.." do"..(#node.Body > 0 and "\n"..compiler.Compile(node.Body, indent+1) or " ").."end"
end

function compiler.CompileWhileStmt(node, indent)
    return "while "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Condition}::Ast.ExprStmt).." do"..(#node.Body > 0 and "\n"..compiler.Compile(node.Body, indent+1) or " ").."end"
end

function compiler.CompileIfStmt(node, indent)
    local result = "if "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Condition}::Ast.ExprStmt).." then"..(#node.ThenBody > 0 and "\n"..compiler.Compile(node.ThenBody, indent+1)..string.rep("\t", indent) or " ")

    if node.ElseBody ~= nil then
        return result.."else"..((node.ElseBody.Kind and node.ElseBody.Kind == "if"::Ast.NodeType) and compiler.CompileIfStmt(node.ElseBody::Ast.If, indent) or " "..(#node.ElseBody > 0 and "\n"..compiler.Compile(node.ElseBody, indent+1)..string.rep("\t", indent) or " ").."end")
    else
        return result.."end"
    end
end

function compiler.CompileFunctionDeclarationStmt(node, indent)
    local result = "function "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Name}::Ast.ExprStmt).."("

    for index, parameter in node.Parameters do
        result = result..parameter.Value..(#node.Parameters ~= index and ", " or "")
    end

    return result..")"..(#node.Body > 0 and "\n"..compiler.Compile(node.Body, indent+1) or " ").."end"
end

function compiler.CompileClassDeclarationStmt(node, indent)
    local classObjectType = "type CLASS_"..node.Name.Value.."_OBJ_T = {"
    local classInstanceType = "type CLASS_"..node.Name.Value.."_INST_T = {"
    local classThisArray = "local CLASS_"..node.Name.Value.."_THIS_LIST: {CLASS_"..node.Name.Value.."_INST_T} = {}"
    local result = "local "..node.Name.Value..": CLASS_"..node.Name.Value.."_OBJ_T = {new = function("

    if node.Initializer then
        classObjectType = classObjectType.."new: ("

        for index, parameter in node.Initializer.Parameters do
            classObjectType = classObjectType..parameter.Value..": any"..(index ~= #node.Initializer.Parameters and ", " or "")
        end

        classObjectType = classObjectType..")->CLASS_"..node.Name.Value.."_INST_T,"
    else
        node.Initializer = {Kind="class_method"::Ast.NodeType, Name={Kind="identifier"::Ast.NodeType, Value=node.Name.Value}::Ast.Identifier, Parameters={}, Body={}}::Ast.ClassMethod
        classObjectType = classObjectType.."new: ()->CLASS_"..node.Name.Value.."_INST_T,"
    end

    for index, parameter in node.Initializer.Parameters do
        result = result..parameter.Value..(index ~= #node.Initializer.Parameters and ", " or "")
    end

    result = result..")\n"..string.rep("\t", indent+1).."local CLASS_"..node.Name.Value.."_THIS_INDEX = #CLASS_"..node.Name.Value.."_THIS_LIST+1\n"..string.rep("\t", indent+1)..string.rep("\t", indent+1).."CLASS_"..node.Name.Value.."_THIS_LIST[CLASS_"..node.Name.Value.."_THIS_INDEX] = {"

    for _, variable in node.Variables do
        result = result.."\n"..string.rep("\t", indent+2)..variable.Name.Value.." = "..(variable.Value == nil and "nil" or compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=variable.Value}::Ast.ExprStmt))..","
        classInstanceType = classInstanceType..variable.Name.Value..": any, " 
    end

    for _, method in node.Methods do
        local name: string = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=method.Name}::Ast.ExprStmt)
        result = result.."\n"..string.rep("\t", indent+2)..name.." = function("
        classInstanceType = classInstanceType..name..": ("

        for index, paramter in method.Parameters do
            result = result..paramter.Value..(index ~= #method.Parameters and ", " or "")
            classInstanceType = classInstanceType..paramter.Value..": any"..(index ~= #method.Parameters and ", " or "")
        end
        
        result = result..")"..(#method.Body > 0 and "\nlocal this = setmetatable(CLASS_"..node.Name.Value.."_THIS_LIST[CLASS_"..node.Name.Value.."_THIS_INDEX], {})\n"..compiler.Compile(method.Body, indent+3)..string.rep("\t", indent+2) or " ").."end,"
        classInstanceType = classInstanceType..")->any, "
    end
    
    return classObjectType.."}".."\n"..classInstanceType.."}\n"..classThisArray.."\n"..result.."\n"..string.rep("\t", indent+1).."}\n"..string.rep("\t", indent+1).."local this = setmetatable(CLASS_"..node.Name.Value.."_THIS_LIST[CLASS_"..node.Name.Value.."_THIS_INDEX], {})\n"..(#node.Initializer.Body > 0 and compiler.Compile(node.Initializer.Body, indent+1) or "\n")..string.rep("\t", indent+1).."\n"..string.rep("\t", indent+1).."return this\nend}"
end

function compiler.CompileSwitchStmt(node, indent)
    local result = "local SWITCH_"..tostring(compiler.switches)..": {[any]: ()->any} = {"

    for key, value in node.Cases do
        result = result.."\n"..string.rep("\t", indent+1).."["..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=key}::Ast.ExprStmt).."] = function()"..(#value > 0 and "\n"..compiler.Compile(value, indent+2).."\n"..string.rep("\t", indent+1) or " ").."end,"
    end

    local expression = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Switcher}::Ast.ExprStmt)
    result = result.."}\nif SWITCH_"..tostring(compiler.switches).."["..expression.."] then\nSWITCH_"..tostring(compiler.switches).."["..expression.."]()\nelse"..(node.Default ~= nil and "\n"..compiler.Compile(node.Default, indent+1) or " ").."end"

    compiler.switches += 1

    return result
end

function compiler.CompileExprStmt(node, indent)
    local switch: {[Ast.NodeType]: (node: Ast.Expr)->string}={
        ["identifier"]=function(node: Ast.Identifier) return node.Value end,
        ["boolean"]=function(node: Ast.Boolean) return tostring(node.Value) end,
        ["string"]=function(node: Ast.String) return "\""..node.Value.."\"" end,
        ["nil"]=function(node: Ast.Nil) return "nil" end,
        ["number"]=function(node: Ast.Number) return tostring(node.Value) end,
        ["new"]=compiler.CompileNewExpr,
        ["binary"]=compiler.CompileBinaryExpr,
        ["call"]=compiler.CompileCallExpr,
        ["member"]=compiler.CompileMemberExpr,
        ["object"]=compiler.CompileObjectExpr,
        ["array"]=compiler.CompileArrayExpr,
    }

    if node.Value and switch[node.Value.Kind] then
        return switch[node.Value.Kind](node.Value, indent or 0)
    else
        error("Lua++/Compiler -> The expression node \""..node.Value.Kind.."\" was not compiled.")
    end
end

function compiler.CompileNewExpr(node, indent)
    local result = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Name}::Ast.ExprStmt)..".new("

    for index, parameter in node.Parameters do
        result = result..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=parameter}::Ast.ExprStmt)..(index ~= #node.Parameters and ", " or "")
    end

    return result..")"
end

function compiler.CompileBinaryExpr(node, indent)
    local unary = false
    local postfix = false

    if node.Left.Kind == "identifier" and (node.Left::Ast.Identifier).Value == node.Operator.Value then
        unary = true
        postfix = false
    elseif node.Right.Kind == "identifier" and (node.Right::Ast.Identifier).Value == node.Operator.Value then
        unary = true
        postfix = true
    end

    if node.Operator.Value == "++" then
        node.Operator.Value = " += 1"
    elseif node.Operator.Value == "--" then
        node.Operator.Value = " -= 1"
    elseif node.Operator.Value == "||" then
        node.Operator.Value = "or"
    elseif node.Operator.Value == "&&" then
        node.Operator.Value = "and"
    elseif node.Operator.Value == "!=" then
        node.Operator.Value = "~="
    elseif node.Operator.Value == "!" then
        node.Operator.Value = "not "
    end

    if not unary then
        return compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Left}::Ast.ExprStmt).." "..node.Operator.Value.." "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Right}::Ast.ExprStmt)
    end

    if postfix then
        return compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Left}::Ast.ExprStmt)..node.Operator.Value
    end

    return node.Operator.Value..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Right}::Ast.ExprStmt, indent)
end

function compiler.CompileMemberExpr(node, indent)
    local result: string = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Object}::Ast.ExprStmt)

    if node.Computed then
        return result.."["..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Property}::Ast.ExprStmt).."]"
    end

    return result..(node.Colon and ":" or ".")..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Property}::Ast.ExprStmt)
end

function compiler.CompileCallExpr(node, indent)
    if node.Caller.Kind == "identifier" and compiler.FunctionOverrides[(node.Caller::Ast.Identifier).Value] then
        return compiler.FunctionOverrides[(node.Caller::Ast.Identifier).Value](compiler, node)
    end

    local result: string = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=node.Caller}::Ast.ExprStmt).."("

    for index, argument in node.Arguments do
        result = result..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=argument}::Ast.ExprStmt)..(index ~= #node.Arguments and ", " or "")
    end

    return result..")"
end

function compiler.CompileObjectExpr(node, indent)
    if #node.Properties <= 0 then
        return "{}"
    end

    local result: string = "{\n"

    for _, property in node.Properties do
        if property.Value then
            if property.Key.Kind ~= "identifier" then
                result = result.."\t"..string.rep("\t", indent).."["..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Key}::Ast.ExprStmt).."] = "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Value}::Ast.ExprStmt)..",\n"
            else
                result = result.."\t"..string.rep("\t", indent)..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Key}::Ast.ExprStmt).." = "..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Value}::Ast.ExprStmt)..",\n"
            end
        else
            local keyExpression: string = compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Key}::Ast.ExprStmt)
            if property.Key.Kind ~= "identifier" then
                result = result.."\t"..string.rep("\t", indent).."["..keyExpression.."] = "..keyExpression..",\n"
            else
                result = result.."\t"..string.rep("\t", indent)..keyExpression.." = "..keyExpression..",\n"
            end
        end
    end

    return result..string.rep("\t", indent).."}"
end

function compiler.CompileArrayExpr(node)
    if #node.Properties <= 0 then
        return "{}"
    end

    local result: string = "{\n"

    for _, property in node.Properties do
        result = result.."\t"..compiler.CompileExprStmt({Kind="expression_statement"::Ast.NodeType, Value=property.Value})..",\n"
    end

    return result.."}"
end

return compiler