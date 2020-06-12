local shared = require("vim/modes/shared")
local messages = require("vim/messages")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local mod = {}

mod.inserter = nil

local function normalMode()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = true
    shared.setMode(require("vim/modes/normal"))
    messages.echo("")
    if mod.inserter then
        mod.inserter:commit()
    end
    mod.inserter = nil
    window.cursor[1] = window.cursor[1] - 1
    window:fixCursor()
    messages.setBottom("")
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

function mod.onSwitch()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = false
    mod.inserter = window.buffer:startInsert(window.cursor)
end

function mod.render()
    messages.setBottom("-- INSERT --", "ModeMsg")
end

return mod
