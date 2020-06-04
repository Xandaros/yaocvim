local shared = require("vim/modes/shared")
local status = require("vim/status")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local mod = {}

mod.inserter = nil

local function normalMode()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = true
    shared.setMode(require("vim/modes/normal"))
    window.cursor[1] = window.cursor[1] - 1
    window:fixCursor()
    status.setStatus("")
    mod.inserter = nil
end

function mod.keyPress(event)
    local window = Tab.getCurrent():getWindow()
    if event:isPrintable() or event:isReturn() then
        mod.inserter:addChar(event.char)
    elseif event.char == "\b" then
        mod.inserter:backspace()
    elseif event:isEscape() then
        normalMode()
    end
    window:updateScroll()
end

function mod.render()
    status.setStatus("-- INSERT --")
end

function mod.onSwitch()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = false
    mod.inserter = window.buffer:startInsert(window.cursor)
end

return mod
