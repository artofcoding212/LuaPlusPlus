--NOTE: This is to be parented under the "luapp.lua" file.

--// Types //--

export type TokenType=
    --LITERALS
    "identifier" |
    "string" |
    "number" |
    --GROUPING/OPERATORS
    "close_paren" |
    "open_paren" |
    "close_bracket" |
    "open_bracket" |
    "open_brace" |
    "close_brace" |
    "semicolon" |
    "colon" |
    "comma" |
    "dot" |
    "equals" |
    "assignment" |
    "bang_equals" |
    "bang" |
    "less_equals" |
    "less" |
    "greater_equals" |
    "greater" |
    "and" |
    "or" |
    "plus" |
    "plus_plus" |
    "plus_equals" |
    "minus" |
    "minus_minus" |
    "minus_equals" |
    "star" |
    "star_equals" |
    "slash" |
    "slash_equals" |
    "percent" |
    "percent_equals" |
    "star_star" |
    "star_star_equals" |
    --KEYWORDS
    "var" |
    "export" |
    "type" |
    "true" |
    "false" |
    "nil" |
    "func" |
    "return" |
    "if" |
    "else" |
    "class" |
    "new" |
    "for" |
    "in" |
    "break" |
    "continue" |
    "while" |
    "switch" |
    "default" |
    --OTHER
    "eof"

export type Token={
    Type: TokenType;
    Value: string;
}

export type Lexer={
    Keywords: {[string]: TokenType};
    Tokens: {Token};
    source: {string};
    
    Alphabetic: (text: string)->boolean;
    Numeric: (text: string)->boolean;
    Skippable: (text: string)->boolean;
    
    CollectString: ()->();
    CollectComment: ()->();
    
    Tokenize: (source: string)->{Token};
}

--// Module //--

local lexer: Lexer={
    Keywords={
        ["var"]="var",
        ["export"]="export",
        ["type"]="type",
        ["true"]="true",
        ["false"]="false",
        ["nil"]="nil",
        ["func"]="func",
        ["return"]="return",
        ["if"]="if",
        ["else"]="else",
        ["class"]="class",
        ["new"]="new",
        ["for"]="for",
        ["break"]="break",
        ["continue"]="continue",
        ["while"]="while",
        ["switch"]="switch",
        ["default"]="default",
        ["in"]="in",
    },
    Tokens={},
    source={},
}

function lexer.Alphabetic(text)
    return text:upper() ~= text:lower()
end

function lexer.Numeric(text)
    return string.match(text, "%d") ~= nil
end

function lexer.Skippable(text)
    return text == "\n" or text == "\t" or text == "\r"
end

function lexer.CollectString()
    local start: string = table.remove(lexer.source, 1)
    local value: string = ""
    
    while type(lexer.source[1]) == "string" and lexer.source[1] ~= "\"" and lexer.source[1] ~= "'" do
        value = value..table.remove(lexer.source, 1)
    end
    
    if type(lexer.source[1]) ~= "string" then
        error("Lua++/Lexer -> An endless string was provided whilst tokenizing a string.")
    end
    
    if lexer.source[1] ~= start then
        error("Lua++/Lexer -> Expected a string to end with \"" + start + "\" whilst tokenizing, instead \"" + lexer.source[1] + "\" was given.")
    end
    
    table.remove(lexer.source, 1)
    table.insert(lexer.Tokens, {Type="string", Value=value}::Token)
end

function lexer.CollectComment()
    if type(lexer.source[2]) ~= "string" or lexer.source[2] ~= "/" then
        return
    end
    
    table.remove(lexer.source, 1)
    table.remove(lexer.source, 1)
    
    while type(lexer.source[1]) == "string" and not lexer.Skippable(lexer.source[1]) do
        table.remove(lexer.source, 1)
    end
end

function lexer.Tokenize(source: string)
    lexer.source = source:split("")
    
    while #lexer.source > 0 do
        local matches: {[string]: ()->()}={
            ["\""] = function() lexer.CollectString() end,
            ["'"] = function() lexer.CollectString() end,
            ["."] = function() table.insert(lexer.Tokens, {Type="dot", Value=table.remove(lexer.source, 1)}::Token) end,
            ["["] = function() table.insert(lexer.Tokens, {Type="open_bracket", Value=table.remove(lexer.source, 1)}::Token) end,
            ["]"] = function() table.insert(lexer.Tokens, {Type="close_bracket", Value=table.remove(lexer.source, 1)}::Token) end,
            [","] = function() table.insert(lexer.Tokens, {Type="comma", Value=table.remove(lexer.source, 1)}::Token) end,
            ["{"] = function() table.insert(lexer.Tokens, {Type="open_brace", Value=table.remove(lexer.source, 1)}::Token) end,
            ["}"] = function() table.insert(lexer.Tokens, {Type="close_brace", Value=table.remove(lexer.source, 1)}::Token) end,
            [":"] = function() table.insert(lexer.Tokens, {Type="colon", Value=table.remove(lexer.source, 1)}::Token) end,
            ["("] = function() table.insert(lexer.Tokens, {Type="open_paren", Value=table.remove(lexer.source, 1)}::Token) end,
            [")"] = function() table.insert(lexer.Tokens, {Type="close_paren", Value=table.remove(lexer.source, 1)}::Token) end,
            [";"] = function() table.insert(lexer.Tokens, {Type="semicolon", Value=table.remove(lexer.source, 1)}::Token) end,
            ["="] = function()
                table.remove(lexer.source, 1)
                
                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="equals", Value="="..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="assignment", Value="="}::Token)
                end
            end,
            ["!"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="bang_equals", Value="!"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="bang", Value="!"}::Token)
                end
            end,
            ["<"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="less_equals", Value="<"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="less", Value="<"}::Token)
                end
            end,
            [">"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="greater_equals", Value=">"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="greater", Value=">"}::Token)
                end
            end,
            ["&"] = function()
                if lexer.source[2] == "&" then
                    table.insert(lexer.Tokens, {Type="and", Value=table.remove(lexer.source, 1)..table.remove(lexer.source, 1)}::Token)
                end
            end,
            ["|"] = function()
                if lexer.source[2] == "|" then
                    table.insert(lexer.Tokens, {Type="or", Value=table.remove(lexer.source, 1)..table.remove(lexer.source, 1)}::Token)
                end
            end,
            ["+"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="plus_equals", Value="+"..table.remove(lexer.source, 1)}::Token)
                elseif lexer.source[1] == "+" then
                    table.insert(lexer.Tokens, {Type="plus_plus", Value="+"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="plus", Value="+"}::Token)
                end
            end,
            ["-"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="minus_equals", Value="-"..table.remove(lexer.source, 1)}::Token)
                elseif lexer.source[1] == "-" then
                    table.insert(lexer.Tokens, {Type="minus_minus", Value="-"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="minus", Value="-"}::Token)
                end
            end,
            ["*"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="star_equals", Value="*"..table.remove(lexer.source, 1)}::Token)
                elseif lexer.source[1] == "*" then
                    table.remove(lexer.source, 1)
                    
                    if lexer.source[1] == "=" then
                        table.insert(lexer.Tokens, {Type="star_star_equals", Value="**"..table.remove(lexer.source, 1)}::Token)
                    else
                        table.insert(lexer.Tokens, {Type="star_star", Value="**"}::Token)
                    end
                else
                    table.insert(lexer.Tokens, {Type="star", Value="*"}::Token)
                end
            end,
            ["/"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="slash_equals", Value="/"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="slash", Value="/"}::Token)
                end
            end,
            ["%"] = function()
                table.remove(lexer.source, 1)

                if lexer.source[1] == "=" then
                    table.insert(lexer.Tokens, {Type="percent_equals", Value="%"..table.remove(lexer.source, 1)}::Token)
                else
                    table.insert(lexer.Tokens, {Type="percent", Value="%"}::Token)
                end
            end,
        }
        
        if matches[lexer.source[1]] then
            matches[lexer.source[1]]()
        elseif lexer.Numeric(lexer.source[1]) then
            local number: string = ""
            
            while #lexer.source > 0 and lexer.Numeric(lexer.source[1]) do
                number = number..table.remove(lexer.source, 1)
                
                if lexer.source[1] == "." then
                    number = number..table.remove(lexer.source, 1)

                    while #lexer.source > 0 and lexer.Numeric(lexer.source[1]) do
                        number = number..table.remove(lexer.source, 1)
                    end
                    
                    break
                end
            end
            
            table.insert(lexer.Tokens, {Type="number", Value=number}::Token)
        elseif lexer.Alphabetic(lexer.source[1]) or lexer.source[1] == "_" then
            local identifier: string = ""

            while #lexer.source > 0 and (lexer.Alphabetic(lexer.source[1]) or lexer.Numeric(lexer.source[1]) or lexer.source[1] == "_") do
                identifier = identifier..table.remove(lexer.source, 1)
            end
            
            if lexer.Keywords[identifier] then
                table.insert(lexer.Tokens, {Type=lexer.Keywords[identifier], Value=identifier})
            else
                table.insert(lexer.Tokens, {Type="identifier", Value=identifier})
            end
        elseif lexer.Skippable(lexer.source[1]) or lexer.source[1] == " " then
            table.remove(lexer.source, 1)
        else
            error("Lua++/Lexer -> The character \"" + lexer.source[1] + "\" was not recognized during tokenization.")
        end
    end
    
    table.insert(lexer.Tokens, {Type="eof", Value="eof"}::Token)
    
    return lexer.Tokens
end

return lexer