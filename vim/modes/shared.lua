local ret = {}

-- ret.mode set it vim/modes/all

function ret.setMode(mode, count)
    if count == nil then
        count = 1
    end
    if type(mode) == "table" then
        ret.mode = mode
    elseif mode == "normal" then
        ret.mode = ret.normal
    elseif mode == "command" then
        ret.mode = ret.command
    end

    if ret.mode.onSwitch ~= nil then
        ret.mode.onSwitch(count)
    end
end

return ret
