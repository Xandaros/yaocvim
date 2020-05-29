local tabs = require("vim/tabs")

local mod = {}

mod.buffers = {}

mod.Buffer = {}
local Buffer = mod.Buffer

Buffer.__index = Buffer

function Buffer.new(content)
	local ret = setmetatable({}, Buffer)
	ret.content = content or {}
	ret.id = #mod.buffers + 1
	ret.name = "[No Name]"
	ret.file = nil
	ret.active = false

	mod.buffers[ret.id] = ret
	return ret
end

function mod.updateActive()
	for _, buffer in ipairs(mod.buffers) do
		buffer.active = false
	end
	for _, tab in ipairs(tabs.tabs) do
		for _, window in ipairs(tab.windows) do
			window.buffer.active = true
		end
	end
end

return mod
