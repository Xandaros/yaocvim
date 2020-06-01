local ret = {}

ret.normal = require("vim/modes/normal")
ret.command = require("vim/modes/command")
ret.shared = require("vim/modes/shared")

ret.shared.mode = ret.normal
ret.setMode = ret.shared.setMode

return ret
