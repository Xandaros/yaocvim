local component = require("component")
local gpu = component.gpu

local mod = {}

mod.screen_dim = {gpu.getResolution()}

function mod.printTable(tbl, tabs)
    if tabs == nil then tabs = 0 end
    local key_length = 0
    for k, _ in pairs(tbl) do
        if #tostring(k) > key_length then
            key_length = #tostring(k)
        end
    end

    local prepend = string.rep("\t", tabs)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(tostring(k) .. ":")
            mod.printTable(v, tabs + 1)
        else
            print(("%s%" .. key_length .. "s: %s"):format(prepend, tostring(k), tostring(v)))
        end
    end
end

function mod.invertColor()
    local bg, bg_pal = gpu.getBackground()
    local fg, fg_pal = gpu.getForeground()

    gpu.setBackground(fg, fg_pal)
    gpu.setForeground(bg, bg_pal)
end

function mod.firstNonBlank(line)
    return string.find(line, "[^ \t]")
end

function mod.map(tbl, f)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[k] = f(v)
    end
    return ret
end

function mod.flip(f)
    return function(a)
        return function(b)
            return f(b)(a)
        end
    end
end

return mod
