local component = require("component")
local gpu = component.gpu

local colors = require("vim/colors")

local mod = {}

mod.message_history = {}
mod.visible_lines = {}
mod.buffered_lines = {}
mod.bottom = nil
mod.prompt_shown = false

local screen_dim = {gpu.getResolution()}

function mod.addMessage(message, persistent, color)
    if color == nil then
        color = "Normal"
    end
    if persistent then
        mod.message_history[#mod.message_history + 1] = message
    end
    mod.buffered_lines[#mod.buffered_lines + 1] = {color, message}
end

function mod.echo(message, color)
    mod.addMessage(message, false, color)
end

function mod.echomsg(message, color)
    mod.addMessage(message, true, color)
end

function mod.error(message)
    mod.addMessage(message, true, "ErrorMsg")
end

--- Just changes the bottommost line instead of the entire status
--- Used for command-line mode
function mod.setBottom(message, color)
    if #mod.visible_lines == 1 then
        mod.visible_lines = {}
    end
    mod.bottom = {color or "Normal", message}
end

function mod.updateVisible()
    if #mod.buffered_lines > 0 then
        if #mod.visible_lines > 1 then
            local len = #mod.visible_lines
            for i=1, #mod.buffered_lines do
                mod.visible_lines[len + i] = mod.buffered_lines[i]
            end
        else
            mod.visible_lines = mod.buffered_lines
        end
        mod.buffered_lines = {}
    end
    mod.bottom = nil
    if #mod.visible_lines > 1 then
        mod.prompt_shown = true
    end
end

function mod.keyPress(event)
    if not mod.prompt_shown then return end
    if event:isReturn() then
        mod.visible_lines = {}
        mod.prompt_shown = false
        return
    end
    if event:isPrintable() then
        if event.char ~= ":" then
            mod.visible_lines = {}
        end
        mod.prompt_shown = false
    end
end

function mod.render()
    local y = screen_dim[2] - #mod.visible_lines
    if #mod.visible_lines > 1 then
        gpu.fill(1, y, screen_dim[1], screen_dim[2] + 1, " ")
    end
    if #mod.visible_lines > 1 then
        y = y - 1
    end
    for i=1, #mod.visible_lines do
        local line = mod.visible_lines[i]
        colors.setColor(line[1])
        gpu.set(1, y + i, line[2])
        colors.setColor("Normal")
    end
    if mod.bottom then
        colors.setColor(mod.bottom[1])
        gpu.set(1, screen_dim[2], mod.bottom[2])
        colors.setColor("Normal")
    elseif #mod.visible_lines > 1 then
        colors.setColor("MoreMsg")
        gpu.set(1, screen_dim[2], "Press ENTER or type command to continue")
        colors.setColor("Normal")
    end
end

return mod
