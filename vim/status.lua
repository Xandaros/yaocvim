local event = require("event")
local component = require("component")
local gpu = component.gpu

local tabs = require("vim/tabs")

local Tab = tabs.Tab

local ret = {}
ret.status = ""

local screen_dim = {gpu.getResolution()}

function ret.setStatus(status)
	ret.status = status

	if status:sub(#status, #status) ~= "\n" then
		status = status .. "\n"
	end
	local lines = {}
	for line in status:gmatch("[^\n]*\n") do
		lines[#lines + 1] = line
	end
	lines[#lines + 1] = "Press ENTER or type command to continue\n"
	if #lines > 2 then
		local y = screen_dim[2] - #lines + 1

		gpu.fill(1, y - 1, screen_dim[1], screen_dim[2] + 1, " ")

		for _, line in ipairs(lines) do
			gpu.set(1, y, line:sub(1, #line - 1))
			y = y + 1
		end

		while true do
			_, _, charcode, keycode, _ = event.pull(nil, "key_down")
			local char = string.char(charcode)
			if char == "\r" then
				ret.status = ""
				break
			end
		end
	end
end

function ret.render()
	gpu.set(1, screen_dim[2], ret.status)
end

return ret
