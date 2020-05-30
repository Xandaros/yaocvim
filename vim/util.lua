local component = require("component")
local gpu = component.gpu

local ret = {}

function ret.printTable(tbl)
    for k, v in pairs(tbl) do
        print(k, v)
    end
end

function ret.invertColor()
    local bg, bg_pal = gpu.getBackground()
    local fg, fg_pal = gpu.getForeground()

    gpu.setBackground(fg, fg_pal)
    gpu.setForeground(bg, bg_pal)
end

return ret
