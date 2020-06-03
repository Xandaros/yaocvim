local tabs = require("vim/tabs")

local mod = {}

mod.buffers = {}

mod.Buffer = {}
local Buffer = mod.Buffer
Buffer.__index = Buffer

mod.Inserter = {}
local Inserter = mod.Inserter
Inserter.__index = Inserter

function Buffer.new(content)
    local ret = setmetatable({}, Buffer)
    ret.content = content or {}
    ret.id = #mod.buffers + 1
    ret.name = "[No Name]"
    ret.file = nil
    ret.active = false

    mod.buffers[ret.id] = ret
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
    for _=start, fin do
        table.remove(self.content, start)
    end
end

function Buffer:deleteNormal(start, fin)
    local before = self.content[start[2]]:sub(1, start[1] - 1)
    local after = self.content[fin[2]]:sub(fin[1] + 1)
    for _=start[2] + 1, fin[2] do
        table.remove(self.content, start[2] + 1)
    end
    self.content[start[2]] = before .. after
end

function Buffer:startInsert(cursor)
    local ret = setmetatable({}, Inserter)

    ret.buffer = self
    ret.cursor = cursor

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
end

function Inserter:backspace()
    local buffer = self.buffer
    local cursor = self.cursor
    local line = buffer.content[cursor[2]]
    local before = line:sub(1, cursor[1] - 2)
    local after = line:sub(cursor[1], #line)
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
