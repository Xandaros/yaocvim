local keyboard = require("keyboard")

local cursor = require("vim/cursor")
local commands = require("vim/commands")
local shared = require("vim/modes/shared")
local messages = require("vim/messages")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Tab = tabs.Tab

local ret = {}

ret.history = {}
ret.history_loc = 1
ret.history_search = nil
ret.command_buffer = ""
ret.cursor = 1

local function normalMode()
    ret.command_buffer = ""
    ret.cursor = 1
    shared.setMode(require("vim/modes/normal"))
end

local function updateHistory()
    if ret.command_buffer == "" then
        return
    end
    local selected = ret.history[ret.history_loc]
    if selected ~= nil and selected == ret.command_buffer then
        table.remove(ret.history, ret.history_loc)
        ret.history[#ret.history + 1] = selected
        ret.history_loc = #ret.history + 1
        return
    end
    ret.history[#ret.history + 1] = ret.command_buffer
    ret.history_loc = #ret.history + 1
    return
end

local function findInHistory(prefix, dir)
    local cur = ret.history_loc
    while cur >= 1 and cur <= #ret.history + 1 do
        cur = cur + dir
        if ret.history[cur] == nil then
            return nil
        end
        if util.startswith(ret.history[cur], prefix) then
            return cur
        end
    end
    return nil
end

function ret.keyPress(event)
    -- Backspace
    if event.char == "\b" then
        if #ret.command_buffer == 0 then
            messages.echo("")
            normalMode()
            return
        end
        if ret.cursor > 1 then
            ret.history_search = ret.command_buffer
            ret.command_buffer = ret.command_buffer:sub(1, ret.cursor - 2) .. ret.command_buffer:sub(ret.cursor)
            ret.cursor = ret.cursor - 1
        end
    -- Enter
    elseif event:isReturn() then
        local command = ret.command_buffer
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
        if ret.cursor > 1 then
            ret.cursor = ret.cursor - 1
        end
    elseif event.keycode == keyboard.keys.right then
        if ret.cursor < #ret.command_buffer + 1 then
            ret.cursor = ret.cursor + 1
        end
    elseif event.keycode == keyboard.keys.up then
        if ret.history_loc > 1 then
            if ret.history_search == nil then
                ret.history_search = ret.command_buffer
            end
            local found_loc = findInHistory(ret.history_search, -1)
            if found_loc then
                ret.history_loc = found_loc
                ret.command_buffer = ret.history[ret.history_loc]
                ret.cursor = #ret.command_buffer + 1
            end
        end
    elseif event.keycode == keyboard.keys.down then
        if ret.history_loc <= #ret.history then
            if ret.history_search == nil then
                ret.history_search = ret.command_buffer
            end
            local found_loc = findInHistory(ret.history_search, 1)
            if found_loc then
                ret.history_loc = found_loc
                ret.command_buffer = ret.history[ret.history_loc]
                ret.cursor = #ret.command_buffer + 1
            else
                ret.command_buffer = ""
                ret.history_loc = #ret.history + 1
            end
            ret.cursor = #ret.command_buffer + 1
        end
    -- Printable char
    elseif event:isPrintable() then
        local before = ret.command_buffer:sub(1, ret.cursor - 1)
        local after = ret.command_buffer:sub(ret.cursor)
        ret.command_buffer = before .. event.char .. after
        ret.cursor = ret.cursor + 1
        ret.history_search = ret.command_buffer
    end
end

function ret.render()
    messages.setBottom(":" .. ret.command_buffer)

    local char_under_cursor = ret.command_buffer:sub(ret.cursor, ret.cursor)
    if char_under_cursor == nil or char_under_cursor == "" then
        char_under_cursor = " "
    end

    cursor.char = char_under_cursor
    cursor.cursor = {ret.cursor + 1, util.screen_dim[2]}
end

function ret.onSwitch(count)
    messages.should_replace = true
    Tab.getCurrent():getWindow().show_cursor = false
    if count == 1 then
        ret.command_buffer = "."
    elseif count > 1 then
        ret.command_buffer = ".,.+" .. tostring(count - 1)
    end
    ret.cursor = #ret.command_buffer + 1
    ret.history_search = ""
end

return ret
