local util = require("vim/util")

local mod = {}

mod.Motion = {
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
local Motion = mod.Motion
Motion.__index = Motion

mod.motions = {}

local function registerMotion(motionspec)
    mod.motions[motionspec.key] = setmetatable(motionspec, Motion)
end

registerMotion({
    key = "j",
    linewise = true,
    execute = function(window, count, args)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] + count}
        if new_pos[2] > #window.buffer.content then
            return nil
        end
        return new_pos
    end
})

registerMotion({
    key = "k",
    linewise = true,
    execute = function(window, count, args)
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1], cur_pos[2] - count}
        if new_pos[2] < 1 then
            return nil
        end
        return new_pos
    end
})

registerMotion({
    key = "h",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] - count, cur_pos[2]}
        if new_pos[1] < 1 then
            return nil
        end
        return new_pos
    end
})

registerMotion({
    key = "l",
    exclusive = true,
    execute = function(window, count, args)
        window:fixCursor()
        local cur_pos = window.cursor
        local new_pos = {cur_pos[1] + count, cur_pos[2]}
        local line = window.buffer.content[new_pos[2]]
        if new_pos[1] > #line then
            return cur_pos
        end
        return new_pos
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
        return {util.firstNonBlank(first_line) or 1, 1}
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
            return false
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

return mod
