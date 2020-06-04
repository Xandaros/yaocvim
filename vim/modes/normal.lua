local normalops = require("vim/normalops")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local ret = {}

ret.command_buffer = ""

function ret.interpret_command()
    local result = normalops.executeNormal(ret.command_buffer)
    if result then
        ret.command_buffer = ""
    end
end

function ret.keyPress(event)
    if not event:isModifier() then
        ret.command_buffer = ret.command_buffer .. event:toVimSyntax()
        ret.interpret_command()
    end
end

function ret.onSwitch()
    Tab.getCurrent():getWindow().show_cursor = true
end

return ret
