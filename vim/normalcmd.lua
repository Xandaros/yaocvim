local tabs = require("vim/tabs")

local Tab = tabs.Tab

local mod = {}

mod.operators = {}
mod.motions = {}

local function registerMotion(motionspec)
	mod.motions[motionspec.key] = motionspec
end

function mod.executeNormal(cmd)
	local first_char = cmd:sub(1, 1)
	if mod.operators[first_char] then
		return mod.operators[first_char].execute()
	elseif mod.motions[first_char] then
		local window = Tab.getCurrent():getWindow()
		local new_cur = mod.motions[first_char].execute(window)
		window.cursor = new_cur
		return true
	end
	return true
end

local function validateCursor(window, cursor)
	local buffer = window.buffer
	if cursor[2] < 1 or cursor[2] > #buffer.content then
		return nil
	end
	if cursor[1] < 1 then
		return nil
	end
	return cursor
end

registerMotion({
	key = "j",
	linewise = true,
	exclusive = false,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1], cur_pos[2] + 1}
		return validateCursor(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "k",
	linewise = true,
	exclusive = false,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1], cur_pos[2] - 1}
		return validateCursor(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "h",
	linewise = false,
	exclusive = true,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1] - 1, cur_pos[2]}
		return validateCursor(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "l",
	linewise = false,
	exclusive = true,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1] + 1, cur_pos[2]}
		return validateCursor(window, new_pos) or cur_pos
	end
})

return mod
