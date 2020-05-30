local ret = {}

ret.normal = require("vim/modes/normal")
ret.command = require("vim/modes/command")
ret.shared = require("vim/modes/shared")

ret.shared.mode = ret.normal

function ret.setMode(mode)
    if type(mode) == "table" then
        ret.shared.mode = mode
    elseif mode == "normal" then
        ret.shared.mode = ret.normal
    elseif mode == "command" then
        ret.shared.mode = ret.command
    end

    if ret.shared.mode.onSwitch ~= nil then
        ret.shared.mode.onSwitch()
    end
end

return ret
