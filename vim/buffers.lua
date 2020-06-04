local tabs = require("vim/tabs")
local undo = require("vim/undo")

local UndoTree = undo.UndoTree
local DeleteLineChange = undo.DeleteLineChange
local DeleteNormalChange = undo.DeleteNormalChange
local InsertChange = undo.InsertChange

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
    ret.id = mod.next_buffer_id
    ret.name = "[No Name]"
    ret.file = nil
    ret.active = false

    ret.undo_tree = UndoTree.new(ret)

    mod.buffers[ret.id] = ret
    mod.next_buffer_id = mod.next_buffer_id + 1
    return ret
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
    end

    deleted[#deleted + 1] = deleted_end

    self.content[start[2]] = before .. after
    self.undo_tree:newChange(DeleteNormalChange.new(start, fin, deleted))
end

function Buffer:undo()
    return self.undo_tree:undo()
end

function Buffer:redo()
    return self.undo_tree:redo()
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
        cursor[2] = cursor[2] + 1
        cursor[1] = 1
    else
        cursor[1] = cursor[1] + 1
        buffer.content[cursor[2]] = before .. char .. after
    end
    self.actions[#self.actions + 1] = char
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
    end
    self.actions[#self.actions + 1] = {"backspace", deletedChar}
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
            latest[2] = latest[2] .. action[2]
        else
            actions[actions_len + 1] = action
        end
    end

    local cursor_end = {self.cursor[1], self.cursor[2]}

    self.buffer.undo_tree:newChange(InsertChange.new(self.cursor_start, cursor_end, actions))
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
