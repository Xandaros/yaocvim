local tabs = require("vim/tabs")
local util = require("vim/util")

local Tab = tabs.Tab

local mod = {}

mod.operators = {}
mod.motions = {}

local function registerMotion(motionspec)
    mod.motions[motionspec.key] = motionspec
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
    exclusive = false,
    jump = false,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] + 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "k",
    linewise = true,
    exclusive = false,
    jump = false,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] - 1}
        return validateCursorY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "h",
    linewise = false,
    exclusive = true,
    jump = false,
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
    linewise = false,
    exclusive = true,
    jump = false,
    execute = function(window)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] + 1, cur_pos[2]}
        return validateCursorXY(window, new_pos) or cur_pos
    end
})

registerMotion({
    key = "$",
    linewise = false,
    exclusive = false,
    jump = false,
    execute = function(window)
        local cursor = window.cursor
        local new_x = #window.buffer.content[cursor[2]]
        return {new_x, cursor[2]}
    end
})

registerMotion({
    key = "0",
    linewise = false,
    exclusive = true,
    jump = false,
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
    exclusive = false,
    jump = true,
    execute = function(window)
        local last_line = window.buffer.content[#window.buffer.content]
        return {util.firstNonBlank(last_line), #window.buffer.content}
    end
})

registerMotion({
    key = "gg",
    linewise = true,
    exclusive = false,
    jump = true,
    execute = function(window)
        local first_line = window.buffer.content[1] or ""
        return {util.firstNonBlank(first_line), 1}
    end
})

registerMotion({
    key = "w",
    linewise = false,
    exclusive = true,
    jump = false,
    execute = function(window)
        local word1 = "[%a%d_]"
        local word2 = "[^%a%d_%s]"
        local cursor = window.cursor
        local cur_line = window.buffer.content[cursor[2]]
        local cur_char = cur_line:sub(cursor[1], cursor[1])
        local after_cursor = cur_line:sub(cursor[1], #cur_line)
        local patterns = {"[^%s]"}

        if string.match(cur_char, word1) then
            patterns = {word2, "%s" .. word1}
        elseif string.match(cur_char, word2) then
            patterns = {word1, "%s" .. word2}
        end
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
            -- no words found on this line, jump to next line's first non-empty char
            local next_line = window.buffer.content[cursor[2] + 1]
            if next_line == nil then
                return cursor
            end
            return {util.firstNonBlank(next_line), cursor[2] + 1}
        end
        local new_x = cursor[1] + idx - 1
        if string.match(cur_line:sub(new_x, new_x), "%s") then
            new_x = new_x + 1
        end
        return {new_x, cursor[2]}
    end
})

return mod
