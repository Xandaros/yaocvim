local component = require("component")
local gpu = component.gpu

local util = require("vim/util")

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

--- Prepare a string for rendering
local function prepareString(s)
	local result, _ = s:gsub("\t", "    ")
	return result
end

--- Turn a location in the text to a coordinate on screen
--- May be out of bounds if the location is not visible
function Window:textToScreenCoords(coords)
	local x, y = table.unpack(coords)
	local ret_x = x - self.screen[1] + 1
	local ret_y = y - self.screen[2] + 1
	return {ret_x, ret_y}
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
			gpu.set(self.x, cur_y, prepareString(visible))
		end
		cur_y = cur_y + 1
	end

	-- Render cursor
	util.invertColor()
	cursor_pos = self:textToScreenCoords(self.cursor)
	local char_under_cursor = buffer.content[self.cursor[2]]:sub(self.cursor[1], self.cursor[1])
	if char_under_cursor == nil
		or char_under_cursor == ""
		or string.byte(char_under_cursor) <= 32
		or string.byte(char_under_cursor) >= 127 then
		char_under_cursor = " "
	end
	gpu.set(cursor_pos[1], cursor_pos[2], char_under_cursor)
	util.invertColor()
end

return mod
