-- Unload all loaded vim modules to prevent persistent state across restarts
for k, v in pairs(package.loaded) do
	if k:sub(1, 3) == "vim" then
		package.loaded[k] = nil
	end
end

local component = require("component")
local event = require("event")
local gpu = component.gpu

local buffers = require("vim/buffers")
local enums = require("vim/enums")
local modes = require("vim/modes/all")
local status = require("vim/status")
local tabs = require("vim/tabs")
local util = require("vim/util")
local windows = require("vim/windows")

local Buffer = buffers.Buffer
local Tab = tabs.Tab
local Window = windows.Window

local screen_dim = {gpu.getResolution()}

local function render()
	gpu.fill(0, 0, screen_dim[1], screen_dim[2] + 1, " ")

	local active_tab = Tab.getCurrent()
	active_tab:render()

	modes.shared.mode.render()
	status.render()
end

local function createInitialTab()
	local bottom_reserve = 1
	local left_reserve = 0

	local first_buffer = Buffer.new()
	first_buffer.active = true
	first_buffer.content = {""}

	Tab.new(first_buffer, left_reserve + 1, 1, screen_dim[1] - left_reserve - 1, screen_dim[2] - bottom_reserve - 1)
end

local function main()
	createInitialTab()
	render()
	while (true) do
		_, _, charcode, keycode, _ = event.pull(nil, "key_down")
		modes.shared.mode.keyPress(charcode, keycode)
		render()
	end
end

main()
