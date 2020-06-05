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

function mod.const(a)
    return function(b)
        return a
    end
end

function mod.split(s, sep)
    local ret = {}
    local last_idx = 0
    while true do
        local start_idx, end_idx = s:find(sep, last_idx + 1)
        if start_idx == nil then
            ret[#ret + 1] = s:sub(last_idx + 1, #s)
            return ret
        end
        ret[#ret + 1] = s:sub(last_idx + 1, start_idx - 1)
        last_idx = end_idx
    end
end

function mod.startswith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

return mod
