local buffers = require("vim/buffers")
local tabs = require("vim/tabs")
local status = require("vim/status")
local windows = require("vim/windows")

local Buffer = buffers.Buffer
local Tab = tabs.Tab
local Window = tabs.Window

local ret = {}

ret.commands = {}
local commands = ret.commands

local quit = { 
	aliases = {"q"},
	execute = function(self, exclamation, args)
		os.exit()
	end
}

local edit = {
	aliases = {"e"},
	execute = function(self, exclamation, args)
		local filename = args[1]
		local window = Tab.getCurrent():getWindow()
		if filename == nil then
			local buffer = window.buffer
			if buffer.file == nil then
				status.setStatus("No file name")
				return
			end
			filename = buffer.file
		end

		local buffer = nil
		for k, v in pairs(buffers.buffers) do
			if v.file == filename then
				buffer = v
			end
		end
		if buffer == nil then
			buffer = Buffer.new()
		end

		local file = io.open(filename)
		if file ~= nil then
			buffer.content = {}
			local line = file:read()
			while line ~= nil do
				buffer.content[#buffer.content + 1] = line
				line = file:read()
			end
			file:close()
		end

		buffer.file = filename
		window.buffer = buffer
	end
}

commands["quit"] = quit
commands["q"] = quit
commands["edit"] = edit
commands["e"] = edit

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
