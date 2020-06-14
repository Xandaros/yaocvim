-- Unload all loaded vim modules to prevent persistent state across restarts
for k, v in pairs(package.loaded) do
    if k:sub(1, 3) == "vim" then
        package.loaded[k] = nil
    end
end

local component = require("component")
local gpu = component.gpu

local buffers = require("vim/buffers")
local colors = require("vim/colors")
local commands = require("vim/commands")
local cursor = require("vim/cursor")
local events = require("vim/events")
local modes = require("vim/modes/all")
local messages = require("vim/messages")
local tabs = require("vim/tabs")

local Buffer = buffers.Buffer
local Tab = tabs.Tab

local screen_dim = {gpu.getResolution()}

local function render()
    colors.setColor("Normal")
    gpu.fill(0, 0, screen_dim[1] + 1, screen_dim[2] + 1, " ")

    local active_tab = Tab.getCurrent()
    active_tab:render()

    if modes.shared.mode.render ~= nil then
        modes.shared.mode.render()
    end
    messages.render()

    cursor.renderCursor()
end

local function createInitialTab(args)
    local bottom_reserve = 1
    local left_reserve = 0

    local first_buffer = Buffer.new()
    if #args > 0 then
        local file = io.open(args[1])
        if file ~= nil then
            first_buffer.content = {}
            local line = file:read()
            while line ~= nil do
                first_buffer.content[#first_buffer.content + 1] = line
                line = file:read()
            end
            file:close()
        end

        first_buffer.file = args[1]
        first_buffer.name = args[1]
    else
        first_buffer.content = {""}
    end
    first_buffer.active = true

    Tab.new(first_buffer, left_reserve + 1, 1, screen_dim[1] - left_reserve - 1, screen_dim[2] - bottom_reserve - 1)
end

local function main(args)
    createInitialTab(args)
    commands.runFile("/home/.vimrc")
    render()
    while (true) do
        local event = events.pull()
        if getmetatable(event) == events.KeyboardEvent then
            messages.keyPress(event)
            modes.shared.mode.keyPress(event)
        end
        render()
    end
end

main({...})
