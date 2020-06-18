local syntax = require("vim/syntax")
local tabs = require("vim/tabs")
local undo = require("vim/undo")

local UndoTree = undo.UndoTree
local DeleteLineChange = undo.DeleteLineChange
local DeleteNormalChange = undo.DeleteNormalChange
local InsertChange = undo.InsertChange
local AddLineChange = undo.AddLineChange

local mod = {}

mod.buffers = {}
mod.next_buffer_id = 1

mod.Buffer = {}
local Buffer = mod.Buffer
Buffer.__index = Buffer

mod.Inserter = {}
local Inserter = mod.Inserter
Inserter.__index = Inserter

function Buffer.new(content)
    local ret = setmetatable({}, Buffer)
    ret.content = content or {}
    ret.colorized_content = {}
    ret.id = mod.next_buffer_id
    ret.name = "[No Name]"
    ret.file = nil
    ret.active = false
    ret.options = {}

    ret.undo_tree = UndoTree.new(ret)

    mod.buffers[ret.id] = ret
    mod.next_buffer_id = mod.next_buffer_id + 1

    ret:colorize()
    return ret
end

function Buffer:colorize(first, last)
    if not first then
        self.colorized_content = {}
        first = 1
        last = #self.content
    end
    if not last then
        last = first
    end
    local state = {}
    for i = first, last do
        local line = self.content[i]
        local segments
        segments, state = syntax.parseLine(line, state)
        self.colorized_content[i] = segments
    end
end

function Buffer:fix()
    if #self.content == 0 then
        self.content[1] = ""
    end
end

function Buffer:deleteLines(start, fin)
    if start > fin then
        local buf = start
        start = fin
        fin = buf
    end
    self.undo_tree:newChange()
    for line_no=fin, start, -1 do
        local line = table.remove(self.content, start)
        table.remove(self.colorized_content, start)
        self.undo_tree:joinChange(DeleteLineChange.new(start, line))
    end
end

function Buffer:deleteNormal(start, fin)
    local before = self.content[start[2]]:sub(1, start[1] - 1)
    local after = self.content[fin[2]]:sub(fin[1] + 1)
    local deleted = {self.content[start[2]]:sub(start[1])}
    local deleted_end = self.content[fin[2]]:sub(1, fin[1])

    for _=start[2] + 1, fin[2] do
        deleted[#deleted + 1] = table.remove(self.content, start[2] + 1)
        table.remove(self.colorized_content, start[2] + 1)
    end

    deleted[#deleted + 1] = deleted_end

    self.content[start[2]] = before .. after
    self.undo_tree:newChange(DeleteNormalChange.new(start, fin, deleted))

    self:colorize(start[2])
end

function Buffer:addLine(line_no, text)
    table.insert(self.content, line_no, text)
    table.insert(self.colorized_content, line_no, {})
    self.undo_tree:newChange(AddLineChange.new(line_no, text))

    self:colorize(line_no)
end

function Buffer:undo()
    return self.undo_tree:undo()
end

function Buffer:redo()
    return self.undo_tree:redo()
end

function Buffer:markWritten()
    self.undo_tree:markWritten()
end

function Buffer:isChanged()
    return self.undo_tree:isChanged()
end

function Buffer:startInsert(cursor)
    local ret = setmetatable({}, Inserter)

    ret.buffer = self
    ret.cursor = cursor
    ret.cursor_start = {cursor[1], cursor[2]}
    ret.actions = {}

    return ret
end

function Inserter:addChar(char)
    local buffer = self.buffer
    local cursor = self.cursor
    local line = buffer.content[cursor[2]]
    local before = line:sub(1, cursor[1] - 1)
    local after = line:sub(cursor[1], #line)
    if char == "\n" or char == "\r" then
        buffer.content[cursor[2]] = before
        table.insert(buffer.content, cursor[2] + 1, after)
        table.insert(buffer.colorized_content, cursor[2] + 1, {})
        cursor[2] = cursor[2] + 1
        cursor[1] = 1
    else
        cursor[1] = cursor[1] + 1
        buffer.content[cursor[2]] = before .. char .. after
    end
    self.actions[#self.actions + 1] = char

    buffer:colorize(cursor[2])
end

function Inserter:backspace()
    local buffer = self.buffer
    local cursor = self.cursor
    local line = buffer.content[cursor[2]]
    local before = line:sub(1, cursor[1] - 2)
    local after = line:sub(cursor[1], #line)
    local deletedChar
    if cursor[1] > 1 then
        deletedChar = buffer.content[cursor[2]]:sub(cursor[1] - 1)
    else
        deletedChar = "\n"
    end
    buffer.content[cursor[2]] = before .. after

    cursor[1] = cursor[1] - 1
    if cursor[1] < 1 then
        cursor[2] = cursor[2] - 1
        if cursor[2] < 1 then
            cursor[1] = 1
            cursor[2] = 1
            return
        end
        local next_line = line
        line = buffer.content[cursor[2]]
        cursor[1] = #line > 0 and #line + 1 or 1
        line = line .. next_line
        buffer.content[cursor[2]] = line
        table.remove(buffer.content, cursor[2] + 1)
        table.remove(buffer.colorized_content, cursor[2] + 1)
    end
    self.actions[#self.actions + 1] = {"backspace", deletedChar}

    buffer:colorize(cursor[2])
end

function Inserter:delete()
    -- TODO: Incomplete
    local buffer = self.buffer
    local cursor = self.cursor
    local line = buffer.content[cursor[2]]
    local before = line:sub(1, cursor[1] - 1)
    local after = line:sub(cursor[1] + 1, #line)
    buffer.content[cursor[2]] = before .. after
end

function Inserter:commit()
    local actions = {}
    for _, action in ipairs(self.actions) do
        local actions_len = #actions
        local latest = actions[actions_len]
        if actions_len == 0 then
            actions[1] = action
        elseif type(latest) == "string" and type(action) == "string" then
            actions[actions_len] = latest .. action
        elseif latest[1] == "backspace" and action[1] == "backspace" then
            latest[2] = action[2] .. latest[2]
        else
            actions[actions_len + 1] = action
        end
    end

    local cursor_end = {self.cursor[1], self.cursor[2]}

    if #actions > 0 then
        self.buffer.undo_tree:newChange(InsertChange.new(self.cursor_start, cursor_end, actions))
    end
end

function mod.updateActive()
    for _, buffer in ipairs(mod.buffers) do
        buffer.active = false
    end
    for _, tab in ipairs(tabs.tabs) do
        for _, window in ipairs(tab.windows) do
            window.buffer.active = true
        end
    end
end

return mod
