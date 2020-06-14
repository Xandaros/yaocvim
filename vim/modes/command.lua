local keyboard = require("keyboard")

local cursor = require("vim/cursor")
local commands = require("vim/commands")
local shared = require("vim/modes/shared")
local messages = require("vim/messages")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Tab = tabs.Tab

local mod = {}

mod.history = {}
mod.history_loc = 1
mod.history_search = nil
mod.command_buffer = ""
mod.cursor = 1

local function normalMode()
    mod.command_buffer = ""
    mod.cursor = 1
    shared.setMode(require("vim/modes/normal"))
end

local function updateHistory()
    if mod.command_buffer == "" then
        return
    end
    local selected = mod.history[mod.history_loc]
    if selected ~= nil and selected == mod.command_buffer then
        table.remove(mod.history, mod.history_loc)
        mod.history[#mod.history + 1] = selected
        mod.history_loc = #mod.history + 1
        return
    end
    mod.history[#mod.history + 1] = mod.command_buffer
    mod.history_loc = #mod.history + 1
    return
end

local function findInHistory(prefix, dir)
    local cur = mod.history_loc
    while cur >= 1 and cur <= #mod.history + 1 do
        cur = cur + dir
        if mod.history[cur] == nil then
            return nil
        end
        if util.startswith(mod.history[cur], prefix) then
            return cur
        end
    end
    return nil
end

function mod.keyPress(event)
    -- Backspace
    if event.char == "\b" then
        if #mod.command_buffer == 0 then
            messages.setBottom(nil)
            normalMode()
            return
        end
        if mod.cursor > 1 then
            mod.history_search = mod.command_buffer
            mod.command_buffer = mod.command_buffer:sub(1, mod.cursor - 2) .. mod.command_buffer:sub(mod.cursor)
            mod.cursor = mod.cursor - 1
        end
    -- Enter
    elseif event:isReturn() then
        local command = mod.command_buffer
        updateHistory()
        normalMode()
        if command ~= "" then
            commands.execute(command)
        end
        messages.updateVisible()
    -- ESC(C-[), F1
    elseif event:isEscape() then
        updateHistory()
        normalMode()
    elseif event.keycode == keyboard.keys.left then
        if mod.cursor > 1 then
            mod.cursor = mod.cursor - 1
        end
    elseif event.keycode == keyboard.keys.right then
        if mod.cursor < #mod.command_buffer + 1 then
            mod.cursor = mod.cursor + 1
        end
    elseif event.keycode == keyboard.keys.up then
        if mod.history_loc > 1 then
            if mod.history_search == nil then
                mod.history_search = mod.command_buffer
            end
            local found_loc = findInHistory(mod.history_search, -1)
            if found_loc then
                mod.history_loc = found_loc
                mod.command_buffer = mod.history[mod.history_loc]
                mod.cursor = #mod.command_buffer + 1
            end
        end
    elseif event.keycode == keyboard.keys.down then
        if mod.history_loc <= #mod.history then
            if mod.history_search == nil then
                mod.history_search = mod.command_buffer
            end
            local found_loc = findInHistory(mod.history_search, 1)
            if found_loc then
                mod.history_loc = found_loc
                mod.command_buffer = mod.history[mod.history_loc]
                mod.cursor = #mod.command_buffer + 1
            else
                mod.command_buffer = ""
                mod.history_loc = #mod.history + 1
            end
            mod.cursor = #mod.command_buffer + 1
        end
    -- Printable char
    elseif event:isPrintable() then
        local before = mod.command_buffer:sub(1, mod.cursor - 1)
        local after = mod.command_buffer:sub(mod.cursor)
        mod.command_buffer = before .. event.char .. after
        mod.cursor = mod.cursor + 1
        mod.history_search = mod.command_buffer
    end
end

function mod.render()
    messages.setBottom(":" .. mod.command_buffer)

    cursor.cursor = {mod.cursor + 1, util.screen_dim[2]}
end

function mod.onSwitch(count)
    messages.should_replace = true
    Tab.getCurrent():getWindow().show_cursor = false
    if count == 1 then
        mod.command_buffer = "."
    elseif count > 1 then
        mod.command_buffer = ".,.+" .. tostring(count - 1)
    end
    mod.cursor = #mod.command_buffer + 1
    mod.history_search = ""
end

return mod
