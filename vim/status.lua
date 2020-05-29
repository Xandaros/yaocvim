local component = require("component")
local gpu = component.gpu

local ret = {}
ret.status = ""

local screen_dim = {gpu.getResolution()}

function ret.setStatus(status)
	ret.status = status
end

function ret.render()
	gpu.set(1, screen_dim[2], ret.status)
end

return ret
