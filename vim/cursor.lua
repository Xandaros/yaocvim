local component = require("component")
local gpu = component.gpu

local colors = require("vim/colors")

local mod = {}

mod.cursor = {1, 1}
mod.char = " "

function mod.renderCursor()
    colors.setColor("Cursor")
    gpu.set(mod.cursor[1], mod.cursor[2], mod.char)
    colors.setColor("Normal")
end

return mod
