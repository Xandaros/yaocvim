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
    return ret
end

function Tab.getCurrent()
    return mod.tabs[mod.active_tab]
end

function Tab:render()
    for k, v in ipairs(self.windows) do
        v:render()
    end
end

function Tab:getWindow()
    return self.windows[self.active_window]
end

return mod
