-- NOTE: This script is designed to contain the Lexer, Parser, Ast, and Compiler ".lua" files.

--// Variables //--

local Lexer = require(script.Lexer)
local Parser = require(script.Parser)
local Ast = require(script.Ast)
local Compiler = require(script.Compiler)

--// Types //--

export type Compiler={
    Compile: (source: string)->string,
}

--// Module //--

return {
    Compile=function(source)
        local tokens: {Lexer.Token} = Lexer.Tokenize(source)
        local ast: Ast.Program = Parser.Parse(tokens)
        
        return Compiler.Compile(ast.Body, 0)
    end
}::Compiler