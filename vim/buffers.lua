local debug = require("vim/debug")
local tabs = require("vim/tabs")

local mod = {}

mod.buffers = {}

mod.Buffer = {}
local Buffer = mod.Buffer

Buffer.__index = Buffer

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
