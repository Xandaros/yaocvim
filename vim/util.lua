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

function ret.firstNonBlank(line)
    return string.find(line, "[^ \t]")
end

function ret.map(tbl, f)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[k] = f(v)
    end
    return ret
end

function ret.flip(f)
    return function(a)
        return function(b)
            return f(b)(a)
        end
    end
end

return ret
