local keyboard = require("keyboard")

local shared = require("vim/modes/shared")
local status = require("vim/status")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local mod = {}

local function normalMode()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = true
    shared.setMode(require("vim/modes/normal"))
end

function mod.keyPress(charcode, keycode)
    local window = Tab.getCurrent():getWindow()
    local cursor = window.cursor
    local buffer = window.buffer
    local char = string.char(charcode)
    if charcode >= 32 and charcode <= 126 then
        local line = buffer.content[cursor[2]]
        line = line:sub(1, cursor[1] - 1) .. char .. line:sub(cursor[1])
        buffer.content[cursor[2]] = line
        cursor[1] = cursor[1] + 1
    elseif charcode == 27 or charcode == 0 and keycode == keyboard.keys.f1 then
        shared.setMode(require("vim/modes/normal"))
        status.setStatus("")
        cursor[1] = cursor[1] - 1
        window:fixCursor()
    end
end

function mod.render()
    status.setStatus("-- INSERT --")
end

function mod.onSwitch()
    local window = Tab.getCurrent():getWindow()
    window.limit_cursor = false
end

return mod
