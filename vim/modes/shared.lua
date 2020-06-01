local ret = {}

-- ret.mode set it vim/modes/all

function ret.setMode(mode)
    if type(mode) == "table" then
        ret.mode = mode
    elseif mode == "normal" then
        ret.mode = ret.normal
    elseif mode == "command" then
        ret.mode = ret.command
    end

    if ret.mode.onSwitch ~= nil then
        ret.mode.onSwitch()
    end
end

return ret
