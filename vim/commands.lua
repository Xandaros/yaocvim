local status = require("vim/status")

local ret = {}

ret.commands = {}
local commands = ret.commands

local quit = { 
	aliases = {"q"},
	execute = function(self, exclamation, args)
		os.exit()
	end
}

commands["quit"] = quit
commands["q"] = quit

function ret.execute(input)
	local split = {}
	for x in input:gmatch("[^ ]+") do
		split[#split + 1] = x
	end
	local command = split[1]
	local exclamation = false
	if command:sub(#command, #command) == "!" then
		exclamation = true
		command = command:sub(1, #command - 1)
	end
	local cmd = commands[command]
	if cmd ~= nil then
		table.remove(split, 1)
		cmd:execute(exclamation, split)
	else
		status.setStatus("Not an editor command: " .. command)
	end
end

return ret
