local keyboard = require("keyboard")

local shared = require("vim/modes/shared")

local ret = {}

ret.command_buffer = ""

function ret.interpret_command()
end

function ret.keyPress(charcode, keycode)
	char = string.char(charcode)
	if char == ":" then
		shared.mode = require("vim/modes/command")
		return
	end
	ret.command_buffer = ret.command_buffer .. char
	ret.interpret_command()
end

function ret.render()
end

return ret
