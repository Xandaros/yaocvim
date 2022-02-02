local component = require("component")
local gpu = component.gpu

local windows = require("vim/windows")

local Window = windows.Window

local mod = {}

mod.tabs = {}
mod.active_tab = 1
mod.Tab = {}

local Tab = mod.Tab

Tab.__index = Tab

function Tab.new(buffer, x, y, w, h)
    local ret = setmetatable({}, Tab)
    mod.tabs[#mod.tabs + 1] = ret

    ret.windows = {}
    ret.windows[1] = Window.new(buffer, x, y, w, h)
    ret.active_window = 1

    ret.x = x
    ret.y = y
    ret.w = w
    ret.h = h

    ret.redraw = false

    ret.options = {}
    return ret
end

function Tab.getCurrent()
    return mod.tabs[mod.active_tab]
end

function Tab:render()
    for k, v in ipairs(self.windows) do
        v:render(self.redraw)
    end
    self.redraw = false
end

function Tab:getWindow()
    return self.windows[self.active_window]
end

function Tab:split()
    local window_height = math.floor(self.h / (#self.windows + 1))
    local extra_height = self.h % (#self.windows + 1)

    local cur_y = 1
    for idx, window in ipairs(self.windows) do
        window.h = window_height
        if idx <= extra_height then
            window.h = window.h + 1
        end
        window.y = cur_y
        cur_y = cur_y + window.h
    end
    local old_window = self:getWindow()
    local new_window = Window.new(old_window.buffer, old_window.x, cur_y, old_window.w, window_height)
    new_window.show_cursor = false
    self.windows[#self.windows + 1] = new_window
    local width, height = gpu.getResolution()
    gpu.fill(1, 1, width, height, " ")
    self.redraw = true
end

function Tab:windowDown()
    if self.active_window < #self.windows then
        self:getWindow().show_cursor = false
        self.active_window = self.active_window + 1
        self:getWindow().show_cursor = true
    end
end

function Tab:windowUp()
    if self.active_window > 1 then
        self:getWindow().show_cursor = false
        self.active_window = self.active_window - 1
        self:getWindow().show_cursor = true
    end
end
return mod
