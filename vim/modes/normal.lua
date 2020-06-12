local messages = require("vim/messages")
local normalops = require("vim/normalops")
local tabs = require("vim/tabs")

local Tab = tabs.Tab

local mod = {}

mod.command_buffer = ""

function mod.interpret_command()
    local result = normalops.executeNormal(mod.command_buffer)
    if result then
        mod.command_buffer = ""
    end
end

function mod.keyPress(event)
    if not event:isModifier() then
        mod.command_buffer = mod.command_buffer .. event:toVimSyntax()
        local cmd = mod.command_buffer
        mod.interpret_command()
        if cmd ~= ":" then
            messages.updateVisible()
        end
    end
end

function mod.onSwitch()
    Tab.getCurrent():getWindow().show_cursor = true
end

return mod
