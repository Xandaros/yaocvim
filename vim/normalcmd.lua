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
        window:updateScroll()
		return true
	end
	return true
end

local function validateCursorX(window, cursor)
    if cursor == nil then
        return nil
    end
	local buffer = window.buffer
	if cursor[1] < 1 then
		return {1, cursor[2]}
	end
    if cursor[1] > #buffer.content[cursor[2]] then
        return {#buffer.content[cursor[2]], cursor[2]}
    end
    return cursor
end

local function validateCursorY(window, cursor)
    if cursor == nil then
        return nil
    end
	local buffer = window.buffer
	if cursor[2] < 1 or cursor[2] > #buffer.content then
		return nil
	end
	return cursor
end

local function validateCursorXY(window, cursor)
    return validateCursorX(window, validateCursorY(window, cursor))
end

registerMotion({
	key = "j",
	linewise = true,
	exclusive = false,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1], cur_pos[2] + 1}
		return validateCursorY(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "k",
	linewise = true,
	exclusive = false,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1], cur_pos[2] - 1}
		return validateCursorY(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "h",
	linewise = false,
	exclusive = true,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1] - 1, cur_pos[2]}
        local line = window.buffer.content[cur_pos[2]]
        if new_pos[1] > #line then
            new_pos[1] = #line - 1
        end
		return validateCursorXY(window, new_pos) or cur_pos
	end
})

registerMotion({
	key = "l",
	linewise = false,
	exclusive = true,
	execute = function(window)
		local cur_pos = window.cursor
		local new_pos = {cur_pos[1] + 1, cur_pos[2]}
		return validateCursorXY(window, new_pos) or cur_pos
	end
})

registerMotion({
    key = "$",
    linewise = false,
    exclusive = false,
    execute = function(window)
		local cursor = window.cursor
        local new_x = #window.buffer.content[cursor[2]]
		return {new_x, cursor[2]}
    end
})

return mod
