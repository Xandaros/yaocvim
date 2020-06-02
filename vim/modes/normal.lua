local keyboard = require("keyboard")

local debug = require("vim/debug")
local normalcmd = require("vim/normalcmd")
local shared = require("vim/modes/shared")
local status = require("vim/status")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local ret = {}

ret.command_buffer = ""

function ret.interpret_command()
    local result = normalcmd.executeNormal(ret.command_buffer)
    if result then
        ret.command_buffer = ""
    end
end

function ret.keyPress(charcode, keycode)
    char = string.char(charcode)
    if char == ":" then
        ret.command_buffer = ""
        shared.setMode(require("vim/modes/command"))
        return
    elseif char == "i" then
        ret.command_buffer = ""
        shared.setMode(require("vim/modes/insert"))
        return
    end
    if charcode >= 32 and charcode <= 126 then
        ret.command_buffer = ret.command_buffer .. char
        ret.interpret_command()
    end
end

function ret.onSwitch()
    Tab.getCurrent():getWindow().show_cursor = true
end

return ret
