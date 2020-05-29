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

	mod.buffers[ret.id] = ret
	return ret
end

return mod
