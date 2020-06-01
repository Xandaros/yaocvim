local component = require("component")

local mod = {}

function mod.log(...)
    if component.ocemu == nil then return end
    component.ocemu.log(...)
end

function mod.logTable(tbl, tabs)
    if component.ocemu == nil then return end

    if tbl == nil then
        component.ocemu.log("nil")
        return
    end
    if tabs == nil then tabs = 0 end
    local key_length = 0
    for k, _ in pairs(tbl) do
        if #tostring(k) > key_length then
            key_length = #tostring(k)
        end
    end

    local prepend = string.rep("    ", tabs)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            component.ocemu.log(prepend .. tostring(k) .. ":")
            mod.logTable(v, tabs + 1)
        else
            component.ocemu.log(("%s%" .. key_length .. "s: %s"):format(prepend, tostring(k), tostring(v)))
        end
    end
end

return mod
