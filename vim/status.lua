local event = require("event")
local component = require("component")
local gpu = component.gpu

local tabs = require("vim/tabs")

local Tab = tabs.Tab

local ret = {}
ret.status = {}

local screen_dim = {gpu.getResolution()}

function ret.setStatus(status)
    if type(status) == "table" then
        ret.status = status
    else
        ret.status = {status}
    end

    local lines = {table.unpack(ret.status)}
    lines[#lines + 1] = "Press ENTER or type command to continue"
    if #lines > 2 then
        local y = screen_dim[2] - #lines + 1

        gpu.fill(1, y - 1, screen_dim[1], screen_dim[2] + 1, " ")

        for _, line in ipairs(lines) do
            gpu.set(1, y, line:sub(1, #line))
            y = y + 1
        end

        while true do
            _, _, charcode, keycode, _ = event.pull(nil, "key_down")
            local char = string.char(charcode)
            if char == "\r" then
                ret.status = {}
                break
            elseif char == ":" then
                local modes = require("vim/modes/all")
                ret.status[#ret.status + 1] = ""
                modes.shared.mode = modes.command
                break
            end
        end
    end
end

--- Just changes the bottommost line instead of the entire status
--- Used for command mode after prompt
function ret.setBottom(status)
    if #ret.status == 0 then
        ret.status = {status}
        return
    end
    ret.status[#ret.status] = status
end

function ret.render()
    local y = screen_dim[2] - #ret.status
    if #ret.status > 1 then
        gpu.fill(1, y, screen_dim[1], screen_dim[2] + 1, " ")
    end
    for i=1, #ret.status do
        gpu.set(1, y + i, ret.status[i])
    end
end

return ret
