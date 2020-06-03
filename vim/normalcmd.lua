local debug = require("vim/debug")
local parser = require("vim/parser")
local shared = require("vim/modes/shared")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Parser = parser.Parser
local Tab = tabs.Tab

local mod = {}

mod.keys = {}

local Operator = {
    key = "",
    priority = false,
    default_count = 1,
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
    default_count = 1,
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

local function sortCursors(cursor1, cursor2)
    if cursor2[2] > cursor1[2] then
        return cursor1, cursor2
    end
    if cursor2[1] > cursor1[1] then
        return cursor1, cursor2
    end
    return cursor2, cursor1
end

local WholeLine = setmetatable({
    key = "<whole line>",
    linewise = true,
    execute = function(window, count, args)
        return window.cursor
    end
}, Motion)


--- returns:
--- True: Invalid input
--- False: Ambiguous input
--- Motion/Operator, string: Valid input, unparsed text
local function findCandidate(cmd, tbl)
    for k, _ in pairs(tbl) do
        if cmd:sub(1, #k) == k then
            return tbl[k], cmd:sub(#k + 1)
        elseif k:sub(1, #cmd) == cmd then
            return false
        end
    end
    return true
end

function mod.executeNormal(cmd)
    local window = Tab.getCurrent():getWindow()

    local register, rest = Parser.string("\""):andAlso(Parser.anyChar()):runParser(cmd)
    local count, rest = Parser.pattern("[1-9]%d*"):map(tonumber):runParser(rest)
    local command, rest = Parser.pattern("[^1-9]+"):runParser(rest)
    local count2, rest = Parser.pattern("[1-9]%d*"):map(tonumber):runParser(rest)
    local command2, rest = Parser.pattern("[^1-9]+"):runParser(rest)
    if command == nil then return false end


    local action, args = findCandidate(command, mod.keys)

    if count == nil and type(action) == "table" then
        count = action.default_count
    end
    if getmetatable(action) == Motion then
        local new_cur = action.execute(window, count, args)
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
            action2, args = findCandidate(command2, mod.keys)
        else
            action2, args = findCandidate(command:sub(#action.key + 1), mod.keys)
            if type(action2) == "table" then
                count2 = action2.default_count
            end
        end

        if action2 == false or getmetatable(action2) == Motion then
            if action2 == false then action2 = nil end
            return action.execute(window, count, count2, action2, args)
        elseif getmetatable(action2) == Operator then
            if action2 == action then
                return action.execute(window, count, count2, WholeLine, args)
            elseif action2.priority then
                return action2.execute(window, action2.default_count, count2, WholeLine, args)
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
        local new_pos = {cur_pos[1], cur_pos[2] + count}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "k",
    linewise = true,
    execute = function(window, count, args)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] - count}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "h",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] - count, cur_pos[2]}
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "l",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] + count, cur_pos[2]}
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
        local cur_x = cursor[1]
        local cur_y = cursor[2]

        local line = window.buffer.content[cur_y]
        for i=1, count do
            local next_word = findNextWord(line, cur_x)
            if next_word == nil then
                cur_y = cur_y + 1
                local next_line = window.buffer.content[cur_y]
                if next_line == nil then
                    return {util.firstNonBlank(line) or 1, cur_y - 1}
                end
                line = next_line
                cur_x = util.firstNonBlank(line) or 1
            else
                cur_x = next_word
            end
        end
        return {cur_x, cur_y}
    end
})

registerMotion({
    key = "e",
    execute = function(window, count, args)
        window:fixCursor()
        local cursor = window.cursor
        local x = cursor[1]
        local y = cursor[2]

        for j=1, count do
            for i=y, #window.buffer.content do
                local cur_line = window.buffer.content[i]
                if cur_line == nil then
                    local line = #window.buffer.content[i - 1]
                    if #line == 0 then
                        return {1, i - 1}
                    else
                        return {#line, i - 1}
                    end
                end
                local word_end = findEndOfWord(cur_line, x)
                if word_end ~= nil then
                    x = word_end
                    y = i
                    goto continue
                end
                x = 1
                y = i
            end
            ::continue::
        end


        return {x, y}
    end
})

registerMotion({
    key = "b",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cursor = window.cursor

        local x = cursor[1]
        local y = cursor[2]

        for i=1, count do
            local cur_line = window.buffer.content[y]
            local reversed = cur_line:reverse()
            local wordEnd_rev = findEndOfWord(reversed, #cur_line - x + 1)
            if wordEnd_rev ~= nil then
                x = #cur_line - wordEnd_rev + 1
                goto continue
            end

            -- No previous word found on this line
            if y == 1 then
                -- Already on first line, just go to 1,1
                return {1, 1}
            end

            -- Go to previous line
            y = y - 1
            cur_line = window.buffer.content[y]
            reversed = cur_line:reverse()
            wordEnd_rev = findEndOfWord(reversed, 1)
            if wordEnd_rev ~= nil then
                x = #cur_line - wordEnd_rev + 1
                goto continue
            else
                x = 1
                goto continue
            end
            ::continue::
        end
        return {x, y}
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
        local x = cursor[1]
        for j=1, count do
            if x == #line then
                return cursor
            end
            for i = x + 1, #line do
                local char = line:sub(i,i)
                if char == args then
                    x = i
                    goto continue
                end
            end
            ::continue::
        end
        return {x, cursor[2]}
    end
})

registerOperator({
    key = ":",
    priority = true,
    default_count = 0,
    execute = function(window, count, motion_count, motion, motion_args)
        shared.setMode(require("vim/modes/command"), count)
        return true
    end,

})

registerOperator({
    key = "i",
    execute = function(window, count, motion_count, motion, motion_args)
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "a",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local line = window.buffer.content[cursor[2]]
        cursor[1] = math.min(cursor[1] + 1, #line + 1)
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "A",
    execute = function(window, count, motion_count, motion, motion_args)
        local line = window.buffer.content[window.cursor[2]]
        window.cursor[1] = #line + 1
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "d",
    execute = function(window, count, motion_count, motion, motion_args)
        if motion == nil then return false end
        local buffer = window.buffer
        local cursor = window.cursor
        local new_cursor = motion.execute(window, motion_count, motion_args)
        if new_cursor == nil then
            return false
        end
        if motion.linewise then
            if new_cursor[2] < 1 then
                return true
            end
            if new_cursor[2] > cursor[2] then
                buffer:deleteLines(cursor[2], new_cursor[2])
            else
                buffer:deleteLines(new_cursor[2], cursor[2])
                cursor[2] = new_cursor[2]
            end
        else
            local start, fin = sortCursors({cursor[1], cursor[2]}, new_cursor)
            if motion.exclusive then
                fin[1] = fin[1] - 1
                if fin[1] < 1 then
                    fin[2] = fin[2] - 1
                    local line = buffer.content[fin[2]]
                    if line == nil then
                        return {1, 1}
                    end
                    fin[1] = #line
                end
            end
            buffer:deleteNormal(start, fin)
            window.cursor = start
            window:fixCursor()
        end
        return true
    end
})

registerOperator({
    key = "D",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local buffer = window.buffer
        local line = buffer.content[cursor[2]]

        buffer:deleteNormal({cursor[1], cursor[2]}, {#line, cursor[2]})
        window:fixCursor()
        return true
    end
})

return mod
