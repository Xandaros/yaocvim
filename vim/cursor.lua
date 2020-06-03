local component = require("component")
local gpu = component.gpu

local util = require("vim/util")

local mod = {}

mod.cursor = {1, 1}
mod.char = " "

function mod.renderCursor()
    util.invertColor()
    gpu.set(mod.cursor[1], mod.cursor[2], mod.char)
    util.invertColor()
end

return mod
