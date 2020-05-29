local component = require("component")
local gpu = component.gpu

local mod = {}

mod.Window = {}

local Window = mod.Window

Window.__index = Window

function Window.new(buffer, x, y, w, h)
	local ret = setmetatable({}, Window)
	ret.buffer = buffer

	ret.cursor = {1, 1}
	ret.screen = {1, 1}

	ret.x = x
	ret.y = y
	ret.w = w
	ret.h = h

	return ret
end

function Window:render()
	local buffer = self.buffer
	if #buffer.content == 0 then
		buffer.content[1] = ""
	end

	local cur_y = self.y
	for idx=self.screen[2], self.h + 1 do
		local line = buffer.content[idx]
		if line ~= nil then
			local visible = line:sub(self.screen[1], self.screen[1] + self.w)
			gpu.set(self.x, cur_y, visible)
		end
		cur_y = cur_y + 1
	end
end

return mod
