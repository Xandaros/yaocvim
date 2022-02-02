local motions = require("vim/motions")
local parser = require("vim/parser")
local shared = require("vim/modes/shared")
local messages = require("vim/messages")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Motion = motions.Motion
local Parser = parser.Parser
local Tab = tabs.Tab

local mod = {}

mod.operators = {}

local Operator = {
    key = "",
    priority = false,
    default_count = 1,
    -- execute returns true on success, false if awaiting motion
    execute = function(window, count, motion_count, motion, motion_args)
    end,
    __tostring = function(self)
        return "Operator<" .. self.key .. ">"
    end
}

Operator.__index = Operator

local function registerOperator(operatorspec)
    mod.operators[operatorspec.key] = setmetatable(operatorspec, Operator)
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
        local cursor = {window.cursor[1], window.cursor[2]}
        cursor[2] = cursor[2] + count - 1
        return cursor
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

local function mergeCandidates(candidate1, args1, candidate2, args2)
    if type(candidate1) == "table" then
        return candidate1, args1
    elseif type(candidate2) == "table" then
        return candidate2, args2
    elseif candidate1 and candidate2 then
        return true
    else
        return false
    end
end

local function getKey(cmd)
    if cmd == nil then return false end
    local action1, args1 = findCandidate(cmd, mod.operators)
    local action2, args2 = findCandidate(cmd, motions.motions)
    return mergeCandidates(action1, args1, action2, args2)
end

function mod.executeNormal(cmd)
    local window = Tab.getCurrent():getWindow()

    local register, rest = Parser.string("\""):andAlso(Parser.anyChar()):runParser(cmd)
    local count, rest = Parser.pattern("[1-9]%d*"):map(tonumber):runParser(rest)
    local command, rest = Parser.pattern("[^1-9]+"):runParser(rest)
    local count2, rest = Parser.pattern("[1-9]%d*"):map(tonumber):runParser(rest)
    local command2, rest = Parser.pattern("[^1-9]+"):runParser(rest)
    if command == nil then return false end

    local action, args = getKey(command)

    if count == nil and type(action) == "table" then
        count = action.default_count
    end
    if getmetatable(action) == Motion then
        local new_cur = action.execute(window, count, args)
        if type(new_cur) == "table" then
            window.cursor = new_cur
            window:updateScroll()
            return true
        else
            if new_cur == nil then
                return true
            end
            return new_cur
        end
    elseif getmetatable(action) == Operator then
        local action2, args2
        if count2 ~= nil then
            action2, args2 = getKey(command2)
        else
            action2, args2 = getKey(command:sub(#action.key + 1))
            if type(action2) == "table" then
                count2 = action2.default_count
            end
        end

        if action2 == false or getmetatable(action2) == Motion then
            if action2 == false then action2 = nil end
            local new_cur = action.execute(window, count, count2, action2, args2)
            if new_cur == nil then
                return true
            end
            return new_cur
        elseif getmetatable(action2) == Operator then
            if action2 == action then
                return action.execute(window, count, count2, WholeLine, args2)
            elseif action2.priority then
                return action2.execute(window, action2.default_count, count2, WholeLine, args2)
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
        window:fixCursor()
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "I",
    execute = function(window, count, motion_count, motion, motion_args)
        window:fixCursor()
        local cursor = window.cursor
        local line = window.buffer.content[cursor[2]]
        window.cursor[1] = util.firstNonBlank(line)
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "a",
    execute = function(window, count, motion_count, motion, motion_args)
        window:fixCursor()
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
        window:fixCursor()
        local line = window.buffer.content[window.cursor[2]]
        window.cursor[1] = #line + 1
        shared.setMode(require("vim/modes/insert"), count)
        return true
    end,
})

registerOperator({
    key = "o",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local buffer = window.buffer
        buffer:addLine(cursor[2] + 1, "")
        cursor[2] = cursor[2] + 1
        cursor[1] = 1
        buffer.undo_tree.join_next = true
        shared.setMode(require('vim/modes/insert'), count)
        return true
    end,
})

registerOperator({
    key = "O",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local buffer = window.buffer
        buffer:addLine(cursor[2], "")
        cursor[1] = 1
        buffer.undo_tree.join_next = true
        shared.setMode(require('vim/modes/insert'), count)
        return true
    end,
})

registerOperator({
    key = "d",
    execute = function(window, count, motion_count, motion, motion_args)
        if motion == nil then return false end
        local buffer = window.buffer
        local cursor = window.cursor
        for _=1, count do
            local new_cursor = motion.execute(window, motion_count, motion_args)
            if new_cursor == nil then
                return true
            elseif new_cursor == false then
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
            end
            buffer.undo_tree.join_all = true
        end
        buffer.undo_tree.join_all = false
        window:fixCursor()
        return true
    end
})

registerOperator({
    key = "c",
    execute = function(window, count, motion_count, motion, motion_args)
        if motion == nil then return false end
        local buffer = window.buffer
        local cursor = window.cursor
        for _=1, count do
            local new_cursor = motion.execute(window, motion_count, motion_args)
            if new_cursor == nil then
                return true
            elseif new_cursor == false then
                return false
            end
            if motion.linewise then
                if new_cursor[2] < 1 then
                    return true
                end
                if new_cursor[2] > cursor[2] then
                    buffer:deleteLines(cursor[2], new_cursor[2])
                    buffer.undo_tree.join_next = true
                    buffer:addLine(cursor[2], "")
                    buffer.undo_tree.join_next = true
                    shared.setMode(require("vim/modes/insert"), count)
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
                buffer.undo_tree.join_next = true
                shared.setMode(require("vim/modes/insert"), count)
            end
            buffer.undo_tree.join_all = true
        end
        buffer.undo_tree.join_all = false
        window:fixCursor()
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

registerOperator({
    key = "<C-u>",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local screen = window.screen
        local move_amount = count * math.ceil(window.h / 2)

        screen[2] = math.max(1, screen[2] - move_amount)
        cursor[2] = math.max(1, cursor[2] - move_amount)

        window:fixCursor()
        return true
    end
})

registerOperator({
    key = "<C-d>",
    execute = function(window, count, motion_count, motion, motion_args)
        local cursor = window.cursor
        local screen = window.screen
        local move_amount = count * math.ceil(window.h / 2)
        local max_move = #window.buffer.content - window.h - screen[2]

        screen[2] = math.min(screen[2] + max_move, screen[2] + move_amount)
        cursor[2] = math.min(#window.buffer.content, cursor[2] + move_amount)

        window:fixCursor()
        return true
    end
})

registerOperator({
    key = "u",
    execute = function(window, count, motion_count, motion, motion_args)
        local new_cursor = window.buffer:undo()
        if new_cursor then
            window.cursor = new_cursor
            window:fixCursor()
        else
            messages.echo("Already at oldest change")
        end
        return true
    end
})

registerOperator({
    key = "<C-r>",
    execute = function(window, count, motion_count, motion, motion_args)
        local new_cursor = window.buffer:redo()
        if new_cursor then
            window.cursor = new_cursor
            window:fixCursor()
        else
            messages.echo("Already at newest change")
        end
        return true
    end
})

registerOperator({
    key = "<C-l>",
    execute = function(window, count, motion_count, motion, motion_args)
        window.buffer:colorize()
        Tab.getCurrent().redraw = true
    end
})

registerOperator({
    key = "<C-w>j",
    execute = function(window, count, motion_count, motion, motion_args)
        Tab.getCurrent():windowDown()
    end
})

registerOperator({
    key = "<C-w>k",
    execute = function(window, count, motion_count, motion, motion_args)
        Tab.getCurrent():windowUp()
    end
})

return mod
