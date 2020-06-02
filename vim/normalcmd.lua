local debug = require("vim/debug")
local parser = require("vim/parser")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Parser = parser.Parser
local Tab = tabs.Tab

local mod = {}

mod.keys = {}

local Operator = {
    key = "",
    execute = function(window, count, motion_count, motion, motion_args)
    end,
    __tostring = function(self)
        return "Operator<" .. self.key .. ">"
    end
}

Operator.__index = Operator

local Motion = {
    key = "",
    linewise = false,
    exclusive = false,
    jump = false,
    execute = function(window, count, args)
    end,
    __tostring = function(self)
        return "Motion<" .. self.key .. ">"
    end
}

Motion.__index = Motion

local function registerOperator(operatorspec)
    mod.keys[operatorspec.key] = setmetatable(operatorspec, Operator)
end

local function registerMotion(motionspec)
    mod.keys[motionspec.key] = setmetatable(motionspec, Motion)
end

local function findLongestMatch(str, tbl)
    local key = ""
    for k, _ in pairs(tbl) do
        if str:sub(1, #k) == k then
            if #k > #key then
                key = k
            end
        end
    end
    return tbl[key], str:sub(#key + 1)
end

local function findCandidates(str, tbl)
    local ret = {}
    for k, v in pairs(tbl) do
        if k:sub(1, #str) == str then
            ret[#ret + 1] = v
        end
    end
    return ret
end


--- returns:
--- True: Invalid input
--- False: Ambiguous input
--- Motion/Operator, string: Valid input, unparsed text
local function getKey(cmd)
    if cmd == nil then
        return false
    end
    do
        local candidates = findCandidates(cmd, mod.keys)
        if #candidates > 0 then
            local key = candidates[1].key
            if cmd:sub(1, #key) ~= key then
                return false
            end
        end
    end

    local action, rest = findLongestMatch(cmd, mod.keys)
    if action == nil then
        return true
    end
    return action, rest
end

local WholeLine = setmetatable({
    key = "<whole line>",
    linewise = true,
    execute = function(window, count, args)
        return window.cursor
    end
}, Motion)

function mod.executeNormal(cmd)
    local window = Tab.getCurrent():getWindow()

    local register, rest = Parser.string("\""):andAlso(Parser.anyChar()):runParser(cmd)
    local count, rest = Parser.option(1)(Parser.many1(Parser.digit())):runParser(rest)
    local command, rest = Parser.pattern("[^%d]+"):runParser(rest)
    local count2, rest = Parser.many1(Parser.digit()):runParser(rest)
    local command2, rest = Parser.pattern("[^%d]+"):runParser(rest)
    if command == nil then return false end


    local action, args = getKey(command)

    if getmetatable(action) == Motion then
        local new_cur = action.execute(window, 1, args)
        if new_cur ~= nil then
            window.cursor = new_cur
            window:updateScroll()
            return true
        else
            return false
        end
    elseif getmetatable(action) == Operator then
        local action2, args
        if count2 ~= nil then
            action2, args = getKey(command2)
        else
            count2 = 1
            action2, args = getKey(command:sub(#action.key + 1))
        end

        if action2 == false or getmetatable(action2) == Motion then
            if action2 == false then action2 = nil end
            return action.execute(window, count, count2, action2, args)
        elseif getmetatable(action2) == Operator then
            if action2 == action then
                return action.execute(window, count, count2, WholeLine, args)
            else
                return true
            end
        else
            return action2
        end
    else
        return action
    end
end

local function validateCursorX(window, cursor)
    if cursor == nil then
        return nil
    end
    local buffer = window.buffer
    if cursor[1] < 1 then
        return {1, cursor[2]}
    end
    local length = #buffer.content[cursor[2]]
    if length == 0 then length = 1 end
    if cursor[1] > length then
        return {length, cursor[2]}
    end
    return cursor
end

local function validateCursorY(window, cursor)
    if cursor == nil then
        return nil
    end
    local buffer = window.buffer
    if cursor[2] < 1 or cursor[2] > #buffer.content then
        return nil
    end
    return cursor
end

local function validateCursorXY(window, cursor)
    return validateCursorX(window, validateCursorY(window, cursor))
end

registerMotion({
    key = "j",
    linewise = true,
    execute = function(window, count, args)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] + 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "k",
    linewise = true,
    execute = function(window, count, args)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] - 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "h",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] - 1, cur_pos[2]}
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "l",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] + 1, cur_pos[2]}
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "$",
    execute = function(window, count, args)
        local cursor = window.cursor
        local new_x = #window.buffer.content[cursor[2]]
        if new_x < 1 then
            new_x = 1
        end
        return {new_x, cursor[2]}
    end
})

registerMotion({
    key = "0",
    exclusive = true,
    execute = function(window, count, args)
        local cursor = window.cursor
        return {1, cursor[2]}
    end
})

registerMotion({
    key = "^",
    linewise = false,
    exclusive = true,
    jump = false,
    execute = function(window, count, args)
        local cursor = window.cursor
        local line = window.buffer.content[cursor[2]]
        return {util.firstNonBlank(line), cursor[2]}
    end
})

registerMotion({
    key = "G",
    linewise = true,
    jump = true,
    execute = function(window, count, args)
        local last_line = window.buffer.content[#window.buffer.content]
        return {util.firstNonBlank(last_line), #window.buffer.content}
    end
})

registerMotion({
    key = "gg",
    linewise = true,
    jump = true,
    execute = function(window, count, args)
        local first_line = window.buffer.content[1] or ""
        return {util.firstNonBlank(first_line), 1}
    end
})

local function findNextWord(str, pos)
    if pos == nil then return nil end
    local after_cursor = str:sub(pos, #str)
    local patterns = {
        "[^%a%d_][%a%d_]",
        "[%a%d_%s][^%a%d_%s]"
    }

    local idx = nil
    for _, pattern in ipairs(patterns) do
        local i, _ = string.find(after_cursor, pattern)
        if i ~= nil then
            i = i + 1
            if idx == nil or i < idx then
                idx = i
            end
        end
    end
    if idx == nil then
        return nil
    end
    local new_x = pos + idx - 1
    return new_x
end

local function findEndOfWord(str, pos)
    if pos == nil then return nil end
    local after_cursor = str:sub(pos + 1, #str) .. " "
    local patterns = {
        "[%a%d_][^%a%d_]",
        "[^%a%d_%s][%a%d_%s]"
    }

    local idx = nil
    for _, pattern in ipairs(patterns) do
        local i, _ = string.find(after_cursor, pattern)
        if i ~= nil then
            if idx == nil or i < idx then
                idx = i
            end
        end
    end
    if idx == nil then
        return nil
    end

    return pos + idx
end

registerMotion({
    key = "w",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cursor = window.cursor
        local cur_line = window.buffer.content[cursor[2]]
        local next_word = findNextWord(cur_line, cursor[1])

        if next_word == nil then
            -- no words found on this line, jump to next line's first non-empty char
            local next_line = window.buffer.content[cursor[2] + 1]
            if next_line == nil then
                return cursor
            end
            return {util.firstNonBlank(next_line) or 1, cursor[2] + 1}
        end
        return {next_word, cursor[2]}
    end
})

registerMotion({
    key = "e",
    execute = function(window, count, args)
        window:fixCursor()
        local cursor = window.cursor
        local x = cursor[1]
        for i=cursor[2], #window.buffer.content do
            local cur_line = window.buffer.content[i]
            local word_end = findEndOfWord(cur_line, x)
            if word_end ~= nil then
                return {word_end, i}
            end
            x = 1
        end
        return {#window.buffer.content[#window.buffer.content], #window.buffer.content}
    end
})

registerMotion({
    key = "b",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cursor = window.cursor

        local cur_line = window.buffer.content[cursor[2]]
        local reversed = cur_line:reverse()
        local wordEnd_rev = findEndOfWord(reversed, #cur_line - cursor[1] + 1)
        if wordEnd_rev ~= nil then
            local ret = #cur_line - wordEnd_rev + 1
            return {ret, cursor[2]}
        end
        if cursor[2] == 1 then
            return {1, cursor[2]}
        end
        cur_line = window.buffer.content[cursor[2] - 1]
        reversed = cur_line:reverse()
        wordEnd_rev = findEndOfWord(reversed, 1)
        if wordEnd_rev ~= nil then
            local ret = #cur_line - wordEnd_rev + 1
            return {ret, cursor[2] - 1}
        else
            return {1, cursor[2] - 1}
        end
    end
})

registerMotion({
    key = "f",
    execute = function(window, count, args)
        local cursor = window.cursor
        if #args == 0 then
            return nil
        end
        local line = window.buffer.content[cursor[2]]
        for i = cursor[1], #line do
            local char = line:sub(i,i)
            if char == args then
                return {i, cursor[2]}
            end
        end
        return cursor
    end
})

registerOperator({
    key = "d",
    execute = function(window, count, motion_count, motion, motion_args)
        if motion == nil then return false end
        local buffer = window.buffer
        local cursor = window.cursor
        local new_cursor = motion.execute(window, motion_count, motion_args)
        for i=1, (new_cursor[2] - cursor[2] + 1) * count do
            table.remove(buffer.content, cursor[2])
        end
        return true
    end
})

return mod
