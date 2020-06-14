local mod = {}

-- mod.mode set it vim/modes/all

function mod.setMode(mode, count)
    if count == nil then
        count = 1
    end
    if type(mode) == "table" then
        mod.mode = mode
    end

    if mod.mode.onSwitch ~= nil then
        mod.mode.onSwitch(count)
    end
end

return mod
