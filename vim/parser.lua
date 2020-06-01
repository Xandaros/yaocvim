local util = require("vim/util")

local mod = {}

mod.Parser = {}
local Parser = mod.Parser
Parser.__index = Parser

function Parser:parse(input)
    if type(input) ~= "string" then
        return nil
    end
    local match, rest = self.run(input)
    return match
end

function Parser:runParser(input)
    if type(input) ~= "string" then
        return nil
    end
    return self.run(input)
end

---------------
-- Primitive --
---------------

function Parser.func(func)
    local ret = setmetatable({}, Parser)
    ret.run = func
    return ret
end

-----------
-- Monad --
-----------

function Parser:andThen(f)
    return Parser.func(function(input)
        local match1, rest = self.run(input)
        if match1 == nil then return nil, rest end

        local match2, rest2 = f(match1).run(rest)
        if match2 == nil then
            return nil, input
        end
        return match2, rest2
    end)
end

function Parser:andAlso(parser)
    return self:andThen(function(_) return parser end)
end

function Parser.pure(s)
    return Parser.func(function(input)
        return s, input
    end)
end

function Parser.fail(s)
    return Parser.func(function(input)
        return nil, input
    end)
end

-----------------
-- Alternative --
-----------------

function Parser:orElse(parser)
    return Parser.func(function(input)
        local match1, rest1 = self.run(input)
        if match1 ~= nil then
            return match1, rest1
        end
        return parser.run(input)
    end)
end

----------
-- Char --
----------

function Parser.string(s)
    return Parser.func(function(input)
        if input:sub(1, #s) == s then
            input = input:sub(#s + 1)
            return s, input
        end
        return nil, input
    end)
end

function Parser.pattern(pat)
    return Parser.func(function(input)
        local match = string.match(input, pat)
        if match ~= nil then
            input = input:sub(#match + 1)
        end
        return match, input
    end)
end

function Parser.oneOf(s)
    return Parser.func(function(input)
        local chars = {}
        for i = 1, #s do
            chars[#chars + 1] = s:sub(i, i)
        end
        local parsers = util.map(chars, Parser.string)
        return Parser.choice(parsers).run(input)
    end)
end

function Parser.noneOf(s)
    return Parser.func(function(input)
        local chars = {}
        for i = 1, #s do
            chars[#chars + 1] = s:sub(i, i)
        end
        local parsers = util.map(chars, Parser.string)
        for _, parser in pairs(parsers) do
            local match, rest = parser.run(input)
            if match ~= nil then
                return nil, input
            end
        end
        return Parser.anyChar().run(input)
    end)
end

function Parser.space()
    return Parser.pattern("%s")
end

function Parser.spaces()
    return Parser.many(Parser.space())
end

function Parser.alphanum()
    return Parser.pattern("[%a%d]")
end

function Parser.letter()
    return Parser.pattern("%a")
end

function Parser.digit()
    return Parser.pattern("%d")
end

function Parser.anyChar()
    return Parser.func(function(input)
        return input:sub(1, 1), input:sub(2)
    end)
end

function Parser.satisfy(f)
    return Parser.anyChar():andThen(function(match)
        return Parser.func(function(input)
            return f(match) and Parser.pure(match) or Parser.fail()
        end)
    end)
end

-----------------
-- Combinators --
-----------------

function Parser.choice(...)
    local args = {...}
    return Parser.func(function(input)
        if #args == 0 then
            return nil, input
        end
        local parsers = args[1]
        if getmetatable(parsers) == Parser then
            parsers = args
        end
        for _, parser in pairs(parsers) do
            local match, rest = parser.run(input)
            if match ~= nil then
                return match, rest
            end
        end
        return nil, input
    end)
end

function Parser.inOrder(...)
    local args = {...}
    return Parser.func(function(input)
        if #args == 0 then
            return nil, input
        end
        local parsers = args[1]
        if getmetatable(parsers) == Parser then
            parsers = args
        end
        local match, rest = "", input
        local prev_match = nil
        for _, parser in pairs(parsers) do
            if type(parser) == "function" then
                parser = parser(prev_match)
            end
            local cur_match, cur_rest = parser.run(rest)
            if cur_match == nil then
                return nil, input
            end
            prev_match = cur_match
            match = match .. cur_match
            rest = cur_rest
        end
        return match, rest
    end)
end

function Parser.count(n)
    return function(parser)
        if n <= 0 then
            return Parser.pure({})
        end
        return Parser.func(function(input)
            local match, rest = "", input
            for i=1, n do
                local cur_match, cur_rest = parser.run(rest)
                if cur_match == nil then
                    return nil, input
                end
                match = match .. cur_match
                rest = cur_rest
            end
            return match, rest
        end)
    end
end

function Parser.between(open)
    return function(close)
        return function(inner)
            -- open >> inner >>= (\match -> close >> pure match)
            return open:andAlso(inner:andThen(function(match) return close:andAlso(Parser.pure(match)) end))
        end
    end
end

function Parser.option(default)
    return function(parser)
        return parser:orElse(Parser.pure(default))
    end
end

function Parser.optional(parser)
    return parser:orElse(Parser.pure(""))
end

function Parser.many(parser)
    return Parser.func(function(input)
        local match, rest = "", input
        while true do
            local cur_match, cur_rest = parser.run(rest)
            if cur_match == nil or rest == "" then
                return match, rest
            end
            match = match .. cur_match
            rest = cur_rest
        end
    end)
end

function Parser.many1(parser)
    return Parser.inOrder(
        parser,
        Parser.many(parser)
    )
end

return mod
