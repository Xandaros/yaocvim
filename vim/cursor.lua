local component = require("component")
local gpu = component.gpu

local colors = require("vim/colors")

local mod = {}

mod.cursor = {1, 1}
mod.char = " "

function mod.renderCursor()
    colors.setColor("Cursor")
    local char = gpu.get(mod.cursor[1], mod.cursor[2])
    gpu.set(mod.cursor[1], mod.cursor[2], char)
    colors.setColor("Normal")
end

return mod
