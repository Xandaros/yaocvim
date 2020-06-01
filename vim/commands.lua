local component = require("component")

local buffers = require("vim/buffers")
local debug = require("vim/debug")
local parser = require("vim/parser")
local status = require("vim/status")
local tabs = require("vim/tabs")
local util = require("vim/util")
local windows = require("vim/windows")

local Buffer = buffers.Buffer
local Parser = parser.Parser
local Tab = tabs.Tab
local Window = tabs.Window

local ret = {}

ret.commands = {}
local commands = ret.commands

local function range_parser()
    local part_parser = Parser.choice(util.map({
        "[%d.$%%]",
        "'[%a<>]",
        "/[^/]+/?",
        "%?[^?]+%??",
        "\\/",
        "\\%?",
        "\\&"}, Parser.pattern))
    local offset_parser = Parser.oneOf("+-"):andThen(function(sign)
        return Parser.option("1")(Parser.many1(Parser.digit())):andThen(function(number)  -- number <- option "1" (many1 digit)
            return Parser.pure(tonumber(sign .. number))
        end)
    end)
    local full_part = part_parser:andThen(function(part)
        return Parser.option(0)(offset_parser):andThen(function(offset)
            return Parser.pure({part, offset})
        end)
    end)
    -- part1 <- full_part
    -- (char '," >> full_part >>= \part2 -> pure [part1, part2]) <|> pure [part1]
    return full_part:andThen(function(part1)
        return Parser.string(","):andAlso(
            full_part:andThen(function(part2)
                return Parser.pure({part1, part2})
            end)
        ):orElse(Parser.pure({part1}))
    end)
end

local range_handlers = {
    line = function(range, window)
        local buffer = window.buffer
        local range_start, range_end = table.unpack(range)
        if range_end == nil then
            range_end = range_start
        end

        if range_start[1] == "%" then
            return {1, #buffer.content}
        end

        local function rangeToLine(range)
            if tonumber(range[1]) ~= nil then
                return tonumber(range[1]) + range[2]
            elseif range[1] == "." then
                return window.cursor[2] + range[2]
            elseif range[1] == "$" then
                return #buffer.content + range[2]
            end
        end

        local line_start = rangeToLine(range_start)
        local line_end = rangeToLine(range_end)

        if line_start == nil or line_end == nil then
            return nil, "Invalid range"
        end

        if line_start < 1 or line_start > #buffer.content
            or line_end < 1 or line_start > #buffer.content then
            return nil, "Invalid range"
        end

        return {line_start, line_end}
    end,
    none = function(range, window)
        if range[1][1] ~= "" then
            return nil, "No range allowed"
        end
        return 1
    end
}

local Command = {
    aliases = {},
    default_range = ".",
    range_handler = range_handlers.line,
    execute = function(self, range, exclamation, args)
    end
}

Command.__index = Command

local function registerCommand(cmdspec)
    setmetatable(cmdspec, Command)
    for _, alias in ipairs(cmdspec.aliases) do
        commands[alias] = cmdspec
    end
end

registerCommand({
    aliases = {"quit", "q"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, range, exclamation, args)
        os.exit()
    end
})

registerCommand({
    aliases = {"edit", "e"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, range, exclamation, args)
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
        buffer.name = filename
        window.buffer = buffer
        buffers.updateActive()
    end
})

registerCommand({
    aliases = {"buffers", "ls"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, range, exclamation, args)
        local stts = status.status

        for k, v in pairs(buffers.buffers) do
            local current = Tab.getCurrent():getWindow().buffer == v and "%" or " "
            local active = v.active and "a" or "h"
            local name = "\"" .. v.name .. "\""
            local line = 1
            local line = string.format("%3d %s%s   %-30s Line %d", v.id, current, active, name, line)
            stts[#stts + 1] = line
        end
        status.setStatus(stts)
    end
})

registerCommand({
    aliases = {"delete", "d", "de", "del"},
    execute = function(self, range, exclamation, args)
        if range[1] > range[2] then
            status.setStatus("Backwards range given. Not implemented yet")
        end

        local window = Tab.getCurrent():getWindow()
        local buffer = window.buffer
        for i=range[1], range[2] do
            table.remove(buffer.content, range[1])
        end
        buffer:fix()
        local line = buffer.content[range[1]]
        window.cursor[2] = range[1]
        window.cursor[1] = util.firstNonBlank(line) or 1
        window:fixCursor()
    end
})

function ret.execute(input)
    local window = Tab.getCurrent():getWindow()
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
    local range, stripped_command = range_parser():runParser(command)
    debug.log("Range: ")
    debug.logTable(range)
    debug.log("Stripped command:" .. stripped_command)
    local cmd = commands[stripped_command]
    if cmd ~= nil then
        range = range or {{cmd.default_range, 0}}
        local parsed_range, err = cmd.range_handler(range, window)
        if parsed_range == nil then
            status.setStatus(err)
            return
        end
        table.remove(split, 1)
        cmd:execute(parsed_range, exclamation, split)
    else
        status.setStatus("Not an editor command: " .. stripped_command)
    end
end

return ret
