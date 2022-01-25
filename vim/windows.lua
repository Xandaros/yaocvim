local component = require("component")
local gpu = component.gpu

local colors = require("vim/colors")
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

    ret.options = {}

    ret.previous_content = {}
    ret.previous_cursor = {1,1}

    ret.id = mod.next_window_id
    mod.windows[ret.id] = ret
    mod.next_window_id = mod.next_window_id + 1

    return ret
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
    self.buffer:fix()
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

function Window:getBufferCursor(buf_id)
    if self.buffer.id == buf_id then
        return self.cursor
    else
        return self.buffer_cursors[buf_id]
    end
end

local function lineEquals(line1, line2)
    if line1 == nil or line2 == nil then
        return line1 == line2
    end
    if #line1 ~= #line2 then
        return false
    end
    for i=1, #line1 do
        local seg1 = line1[i]
        local seg2 = line2[i]
        if seg1 == nil and seg2 ~= nil or seg2 == nil and seg1 ~= nil then
            return false
        end
        if seg1[1] ~= seg2[1] or seg1[2] ~= seg2[2] then
            return false
        end
    end
    return true
end

function Window:render(redraw)
    local buffer = self.buffer
    if #buffer.content == 0 then
        buffer.content[1] = ""
    end

    local cur_y = self.y
    for idx=self.screen[2], self.screen[2] + self.h do
        local line = buffer.colorized_content[idx]
        if redraw or not lineEquals(line, self.previous_content[cur_y]) or cur_y == self.previous_cursor[2] then
            self.previous_content[cur_y] = line
            gpu.fill(self.x, cur_y, self.w, 1, " ")
            if line ~= nil then
                local x = 1
                local x_on_screen = self.x
                for _, segment in ipairs(line) do
                    local vis_start = self.screen[1] - x
                    if vis_start < 1 then
                        vis_start = 1
                    end
                    local visible = segment[2]:sub(vis_start, vis_start + self.w)
                    colors.setColor(segment[1])
                    gpu.set(x_on_screen, cur_y, visible)
                    colors.setColor("Normal")
                    x = x + #visible
                    x_on_screen = x_on_screen + #visible
                end
            end
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
        cursor.cursor = cursor_pos
        self.previous_cursor = cursor_pos
    end
end

return mod
