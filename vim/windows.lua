local component = require("component")
local gpu = component.gpu

local cursor = require("vim/cursor")

local mod = {}

mod.windows = {}
mod.next_window_id = 1000

mod.Window = {}

local Window = mod.Window

Window.__index = Window

function Window.new(buffer, x, y, w, h)
    local ret = setmetatable({}, Window)
    ret.buffer = buffer

    ret.cursor = {1, 1}
    ret.screen = {1, 1}

    ret.buffer_cursors = {}
    ret.buffer_cursors[buffer.id] = {1, 1}

    ret.x = x
    ret.y = y
    ret.w = w
    ret.h = h

    ret.show_cursor = true
    ret.limit_cursor = true

    ret.id = mod.next_window_id
    mod.windows[ret.id] = ret
    mod.next_window_id = mod.next_window_id + 1

    return ret
end

--- Prepare a string for rendering
local function prepareString(s)
    local result, _ = s:gsub("\t", "    ")
    return result
end

--- Turn a location in the text to a coordinate on screen
--- May be out of bounds if the location is not visible
function Window:textToScreenCoords(coords)
    local x, y = table.unpack(coords)
    local ret_x = x - self.screen[1] + 1
    local ret_y = y - self.screen[2] + 1
    return {ret_x, ret_y}
end

function Window:scrollX(amount)
    self.screen[1] = self.screen[1] + amount
end

function Window:scrollY(amount)
    self.screen[2] = self.screen[2] + amount
end

function Window:updateScroll()
    local cur = self:textToScreenCoords(self.cursor)
    if cur[1] < 1 then
        self:scrollX(cur[1] - 1)
    elseif cur[1] > self.w + 1 then
        self:scrollX(cur[1] - self.w - 1)
    elseif cur[2] < 1 then
        self:scrollY(cur[2] - 1)
    elseif cur[2] > self.h + 1 then
        self:scrollY(cur[2] - self.h - 1)
    end
end

function Window:fixCursor(ignoreRight)
    if self.cursor[2] < 1 then
        self.cursor[2] = 1
    end
    if self.cursor[2] > #self.buffer.content then
        self.cursor[2] = #self.buffer.content
    end

    if not ignoreRight then
        local line = self.buffer.content[self.cursor[2]]
        if self.cursor[1] > #line then
            self.cursor[1] = #line
        end
    end
    if self.cursor[1] < 1 then
        self.cursor[1] = 1
    end
end

function Window:setBuffer(buffer)
    local buffers = require("vim/buffers")
    self.buffer_cursors[self.buffer.id] = self.cursor
    self.cursor = self.buffer_cursors[buffer.id] or {1, 1}
    self.buffer = buffer
    buffer:fix()
    self:fixCursor()
    buffers.updateActive()
    self:updateScroll()
end

function Window:render()
    local buffer = self.buffer
    if #buffer.content == 0 then
        buffer.content[1] = ""
    end

    local cur_y = self.y
    for idx=self.screen[2], self.screen[2] + self.h do
        local line = buffer.content[idx]
        if line ~= nil then
            local visible = line:sub(self.screen[1], self.screen[1] + self.w)
            gpu.set(self.x, cur_y, prepareString(visible))
        end
        cur_y = cur_y + 1
    end

    -- Render cursor
    if self.show_cursor then
        local cur_line = buffer.content[self.cursor[2]]
        local cursor_x = self.cursor[1]
        if self.limit_cursor and cursor_x > #cur_line then
            cursor_x = math.max(#cur_line, 1)
        end
        local cursor_pos = self:textToScreenCoords({cursor_x, self.cursor[2]})
        local char_under_cursor = cur_line:sub(cursor_x, cursor_x)
        if char_under_cursor == nil
            or char_under_cursor == ""
            or string.byte(char_under_cursor) <= 32
            or string.byte(char_under_cursor) >= 127 then
            char_under_cursor = " "
        end
        cursor.char = char_under_cursor
        cursor.cursor = cursor_pos
    end
end

return mod
