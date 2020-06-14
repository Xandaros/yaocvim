local mod = {}

mod.normal = require("vim/modes/normal")
mod.command = require("vim/modes/command")
mod.shared = require("vim/modes/shared")

mod.shared.mode = mod.normal
mod.setMode = mod.shared.setMode

return mod
