local mod = {}

mod.UndoTree = {}
local UndoTree = mod.UndoTree
UndoTree.__index = UndoTree

mod.UndoBlock = {}
local UndoBlock = mod.UndoBlock
UndoBlock.__index = UndoBlock

mod.DeleteLineChange = {}
local DeleteLineChange = mod.DeleteLineChange
DeleteLineChange.__index = DeleteLineChange

mod.InsertChange = {}
local InsertChange = mod.InsertChange
InsertChange.__index = InsertChange

function UndoTree.new(buffer)
    local ret = setmetatable({}, UndoTree)

    ret.current = UndoBlock.new()
    ret.buffer = buffer
    ret.join_all = false

    return ret
end

function UndoTree:undo()
    if self.current.previous == nil then
        return false
    end
    local ret = self.current:undo(self.buffer)
    self.current = self.current.previous
    return ret
end

function UndoTree:redo()
    local next_block = self.current.following[self.current.branch_id]
    if next_block == nil then
        return false
    end

    local ret = next_block:redo(self.buffer)
    self.current = next_block
    return ret
end

function UndoTree:joinChange(change)
    self.current:newChange(change)
end

function UndoTree:newChange(change)
    if self.join_all then
        return self:joinChange(change)
    end
    local new_block = UndoBlock.new()
    if change ~= nil then
        new_block:newChange(change)
    end
    new_block.previous = self.current
    self.current.following[#self.current.following + 1] = new_block
    self.current.branch_id = #self.current.following
    self.current = new_block
end

function UndoBlock.new()
    local ret = setmetatable({}, UndoBlock)

    ret.changes = {}
    ret.previous = nil
    ret.following = {}
    ret.branch_id = 0

    return ret
end

function UndoBlock:undo(buffer)
    local last_cursor
    for i=#self.changes, 1, -1 do
        last_cursor = self.changes[i]:undo(buffer)
    end
    return last_cursor
end

function UndoBlock:redo(buffer)
    local last_cursor
    for i=1, #self.changes do
        last_cursor = self.changes[i]:redo(buffer)
    end
    return last_cursor
end

function UndoBlock:newChange(change)
    self.changes[#self.changes + 1] = change
end

function DeleteLineChange.new(line_no, line)
    local ret = setmetatable({}, DeleteLineChange)

    ret.line_no = line_no
    ret.line = line

    return ret
end

function DeleteLineChange:undo(buffer)
    table.insert(buffer.content, self.line_no, self.line)
    return {1, self.line_no}
end

function DeleteLineChange:redo(buffer)
    table.remove(buffer.content, self.line_no)
    return {1, self.line_no}
end

function InsertChange.new(cursor_start, cursor_end, actions)
    local ret = setmetatable({}, InsertChange)
    ret.cursor_start = cursor_start
    ret.cursor_end = cursor_end
    ret.actions = actions
    return ret
end

function InsertChange:undo(buffer)
    local cursor = {table.unpack(self.cursor_end)}
    local inserter = buffer:startInsert(cursor)
    for i=#self.actions, 1, -1 do
        local action = self.actions[i]
        if type(action) == "string" then
            for _=1, #action do
                inserter:backspace()
            end
        elseif action[1] == "backspace" then
            inserter:addChar(action[2])
        end
    end
    return cursor
end

function InsertChange:redo(buffer)
    local cursor = {table.unpack(self.cursor_start)}
    local inserter = buffer:startInsert(cursor)
    for i=1, #self.actions do
        local action = self.actions[i]
        if type(action) == "string" then
            for j=1, #action do
                inserter:addChar(action:sub(j, j))
            end
        elseif action[1] == "backspace" then
            inserter:backspace()
        end
    end
    return cursor
end

return mod
