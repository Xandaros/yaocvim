local component = require("component")
local gpu = component.gpu

local commands = require("vim/commands")
local shared = require("vim/modes/shared")
local status = require("vim/status")

local ret = {}

ret.command_buffer = ""

local function normalMode()
	ret.command_buffer = ""
	shared.mode = require("vim/modes/normal")
	status.setStatus("")
end

function ret.keyPress(charcode, keycode)
	local char = string.char(charcode)
	-- Backspace
	if char == "\b" then
		if #ret.command_buffer == 0 then
			normalMode()
			return
		end
		ret.command_buffer = ret.command_buffer:sub(1, #ret.command_buffer - 1)
	-- Enter
	elseif char == "\r" then
		commands.execute(ret.command_buffer)
		normalMode()
	-- ESC(C-[), F1
	elseif charcode == 27 or charcode == 0 and keycode == 59 then
		normalMode()
	-- Printable char
	elseif charcode >= 32 and charcode <= 126 then
		ret.command_buffer = ret.command_buffer .. char
	end
end

function ret.render()
	 status.setStatus(":" .. ret.command_buffer)
end

return ret
