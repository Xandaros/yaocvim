local component = require("component")
local gpu = component.gpu

local keyboard = require("keyboard")

local cursor = require("vim/cursor")
local commands = require("vim/commands")
local shared = require("vim/modes/shared")
local status = require("vim/status")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Tab = tabs.Tab

local ret = {}

ret.command_buffer = ""
ret.cursor = 1

local function normalMode()
    ret.command_buffer = ""
    ret.cursor = 1
    shared.setMode(require("vim/modes/normal"))
end

function ret.keyPress(charcode, keycode)
    local char = string.char(charcode)
    -- Backspace
    if char == "\b" then
        if #ret.command_buffer == 0 then
            status.setStatus("")
            normalMode()
            return
        end
        if ret.cursor > 1 then
            ret.command_buffer = ret.command_buffer:sub(1, ret.cursor - 2) .. ret.command_buffer:sub(ret.cursor)
            ret.cursor = ret.cursor - 1
        end
    -- Enter
    elseif char == "\r" then
        local command = ret.command_buffer
        normalMode()
        if command ~= "" then
            commands.execute(command)
        end
    -- ESC(C-[), F1
    elseif charcode == 27 or charcode == 0 and keycode == 59 then
        normalMode()
    elseif keycode == keyboard.keys.left then
        ret.cursor = ret.cursor - 1
    elseif keycode == keyboard.keys.right then
        ret.cursor = ret.cursor + 1
    -- Printable char
    elseif charcode >= 32 and charcode <= 126 then
        ret.command_buffer = ret.command_buffer:sub(1, ret.cursor - 1) .. char .. ret.command_buffer:sub(ret.cursor)
        ret.cursor = ret.cursor + 1
    end
end

function ret.render()
    status.setBottom(":" .. ret.command_buffer)

    local char_under_cursor = ret.command_buffer:sub(ret.cursor, ret.cursor)
    if char_under_cursor == nil or char_under_cursor == "" then
        char_under_cursor = " "
    end

    cursor.char = char_under_cursor
    cursor.cursor = {ret.cursor + 1, util.screen_dim[2]}
end

function ret.onSwitch(count)
    Tab.getCurrent():getWindow().show_cursor = false
    if count == 1 then
        ret.command_buffer = "."
    elseif count > 1 then
        ret.command_buffer = ".,.+" .. tostring(count - 1)
    end
    ret.cursor = #ret.command_buffer + 1
end

return ret
