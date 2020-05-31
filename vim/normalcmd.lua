local tabs = require("vim/tabs")
local util = require("vim/util")

local Tab = tabs.Tab

local mod = {}

mod.operators = {}
mod.motions = {}

local Motion = {
    key = "",
    linewise = false,
    exclusive = false,
    jump = false,
    execute = function(window)
    end
}

Motion.__index = Motion

local function registerMotion(motionspec)
    mod.motions[motionspec.key] = setmetatable(motionspec, Motion)
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

function mod.executeNormal(cmd)
    local first_char = cmd:sub(1, 1)
    if mod.operators[first_char] then
        return mod.operators[first_char].execute()
    end
    local candidate_motions = findCandidates(cmd, mod.motions)
    if #candidate_motions == 1 then
        if candidate_motions[1].key ~= cmd then
            return false
        end
        local window = Tab.getCurrent():getWindow()
        local new_cur = candidate_motions[1].execute(window)
        if new_cur ~= nil then
            window.cursor = new_cur
            window:updateScroll()
            return true
        else
            return false
        end
    elseif #candidate_motions > 1 then
        return false
    end
    return true
end

local function validateCursorX(window, cursor)
    if cursor == nil then
        return nil
    end
    local buffer = window.buffer
    if cursor[1] < 1 then
        return {1, cursor[2]}
    end
    if cursor[1] > #buffer.content[cursor[2]] then
        return {#buffer.content[cursor[2]], cursor[2]}
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
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] + 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "k",
    linewise = true,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] - 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "h",
    exclusive = true,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] - 1, cur_pos[2]}
        local line = window.buffer.content[cur_pos[2]]
        if new_pos[1] > #line then
            new_pos[1] = #line - 1
        end
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "l",
    exclusive = true,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] + 1, cur_pos[2]}
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "$",
    execute = function(window)
        local cursor = window.cursor
        local new_x = #window.buffer.content[cursor[2]]
        return {new_x, cursor[2]}
    end
})

registerMotion({
    key = "0",
    exclusive = true,
    execute = function(window)
        local cursor = window.cursor
        return {1, cursor[2]}
    end
})

registerMotion({
    key = "^",
    linewise = false,
    exclusive = true,
    jump = false,
    execute = function(window)
        local cursor = window.cursor
        local line = window.buffer.content[cursor[2]]
        return {util.firstNonBlank(line), cursor[2]}
    end
})

registerMotion({
    key = "G",
    linewise = true,
    jump = true,
    execute = function(window)
        local last_line = window.buffer.content[#window.buffer.content]
        return {util.firstNonBlank(last_line), #window.buffer.content}
    end
})

registerMotion({
    key = "gg",
    linewise = true,
    jump = true,
    execute = function(window)
        local first_line = window.buffer.content[1] or ""
        return {util.firstNonBlank(first_line), 1}
    end
})

local function findNextWord(str, pos)
    if pos == nil then return nil end
    local cur_char = str:sub(pos, pos)
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
    local cur_char = str:sub(pos, pos)
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
    execute = function(window)
        local cursor = window.cursor
        local cur_line = window.buffer.content[cursor[2]]
        local next_word = findNextWord(cur_line, cursor[1])

        if next_word == nil then
            -- no words found on this line, jump to next line's first non-empty char
            local next_line = window.buffer.content[cursor[2] + 1]
            if next_line == nil then
                return cursor
            end
            return {util.firstNonBlank(next_line), cursor[2] + 1}
        end
        return {next_word, cursor[2]}
    end
})

registerMotion({
    key = "e",
    execute = function(window)
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
    execute = function(window)
        local cursor = window.cursor

        local x = cursor[1]
        for i=cursor[2], 1, -1 do
            local cur_line = window.buffer.content[i]
            if x == nil then
                x = #cur_line
            end
            local reversed = cur_line:reverse()
            local wordEnd_rev = findEndOfWord(reversed, #cur_line - x + 1)
            if wordEnd_rev ~= nil then
                local ret = #cur_line - wordEnd_rev + 1
                return {ret, i}
            end
            x = nil
        end
        return cursor
    end
})

return mod
