local buffers = require("vim/buffers")
local colors = require("vim/colors")
local enums = require("vim/enums")
local options = require("vim/options")
local parser = require("vim/parser")
local messages = require("vim/messages")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Buffer = buffers.Buffer
local Parser = parser.Parser
local Tab = tabs.Tab

local mod = {}

mod.commands = {}
local commands = mod.commands

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
        -- number <- option "1" (many1 digit)
        return Parser.option("1")(Parser.many1(Parser.digit())):andThen(function(number)
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
    execute = function(self, invocation)
    end
}

Command.__index = Command

local function registerCommand(cmdspec)
    setmetatable(cmdspec, Command)
    for _, alias in ipairs(cmdspec.aliases) do
        commands[alias] = cmdspec
    end
end

local Invocation = {}
Invocation.__index = Invocation

function Invocation.new(range, exclamation, args, cmdline)
    local ret = setmetatable({}, Invocation)

    ret.range = range
    ret.exclamation = exclamation
    ret.args = args
    ret.cmdline = cmdline

    return ret
end

registerCommand({
    aliases = {"quit", "q"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, invoc)
        if not invoc.exclamation then
            local window = Tab.getCurrent():getWindow()
            for _, buf in ipairs(buffers.buffers) do
                if buf:isChanged() then
                    messages.error("No write since last change in buffer \"" .. buf.name .. "\"")
                    window:setBuffer(buf)
                    return false
                end
            end
        end
        os.exit()
    end
})

registerCommand({
    aliases = {"edit", "e"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, invoc)
        local filename = invoc.args[1]
        local window = Tab.getCurrent():getWindow()
        if not invoc.exclamation and not options.get("hidden") and window.buffer:isChanged() then
            messages.error("No write since last change (add ! to override)")
            return false
        end
        local buffer = nil
        if filename == nil then
            buffer = window.buffer
            if buffer.file == nil then
                messages.error("No file name")
                return false
            end
            if not invoc.exclamation and window.buffer:isChanged() then
                messages.error("No write since last change (add ! to override)")
                return false
            end
            filename = buffer.file
            buffer.undo_tree:resetToWrite()
        else
            for k, v in pairs(buffers.buffers) do
                if v.file == filename then
                    if options.get("hidden") then
                        window:setBuffer(v)
                        return
                    else
                        buffer = v
                        buffer.undo_tree:resetToWrite()
                    end
                end
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
        window:setBuffer(buffer)
        return true
    end
})

registerCommand({
    aliases = {"buffers", "ls"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, invoc)
        local window = Tab.getCurrent():getWindow()

        messages.echo(":" .. invoc.cmdline)

        for k, v in pairs(buffers.buffers) do
            local current = window.buffer == v and "%" or " "
            local active = v.active and "a" or "h"
            local changed = v:isChanged() and "+" or " "
            local name = "\"" .. v.name .. "\""
            local cursor = window:getBufferCursor(v.id) or {0, 0}
            local line_no = cursor[2]
            local line = string.format("%3d %s%s %s %-30s Line %d", v.id, current, active, changed, name, line_no)
            messages.echo(line)
        end
        return true
    end
})

registerCommand({
    aliases = {"delete", "d", "de", "del"},
    execute = function(self, invoc)
        if invoc.range[1] > invoc.range[2] then
            messages.error("Backwards range given. Not implemented yet")
            return false
        end

        local window = Tab.getCurrent():getWindow()
        local buffer = window.buffer
        for i=invoc.range[1], invoc.range[2] do
            table.remove(buffer.content, invoc.range[1])
        end
        buffer:fix()
        local line = buffer.content[invoc.range[1]]
        window.cursor[2] = invoc.range[1]
        window.cursor[1] = util.firstNonBlank(line) or 1
        window:fixCursor()
        return true
    end
})

registerCommand({
    aliases = {"w", "write"},
    execute = function(self, invoc)
        local window = Tab.getCurrent():getWindow()
        local buffer = window.buffer
        local filename = table.concat(invoc.args, " ")
        if filename == "" then
            if buffer.file == nil then
                messages.error("No file name")
                return false
            end
            filename = buffer.file
        end

        local chars = 0
        local f = io.open(filename, "w")
        for _, line in pairs(buffer.content) do
            f:write(line, "\n")
            chars = chars + #line + 1
        end
        f:close()
        buffer:markWritten()
        messages.echo(string.format("\"%s\" %dL, %dC written", filename, #buffer.content, chars))
        return true
    end
})

registerCommand({
    aliases = {"wq"},
    execute = function(self, invoc)
        if mod.execute("w") then
            mod.execute("q")
        end
    end
})

registerCommand({
    aliases = {"set", "se"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, invoc)
        if #invoc.args == 0 then
            messages.error("Not implemented yet")
            return false
        end
        for _, arg in ipairs(invoc.args) do
            local parsed = options.optionparser:parse(arg)
            if not options.isValid(parsed[2]) then
                messages.error("Unknown option: " .. parsed[2])
                return false
            end
            local option = options.getOption(parsed[2])
            if parsed[1] == "change" then
                local value = parsed[4]
                if option.typ == enums.TYPE_NUMBER then
                    value = tonumber(value)
                    if value == nil then
                        messages.error("Number required after=: " .. arg)
                        return false
                    end
                elseif option.typ == enums.TYPE_BOOLEAN then
                    messages.error("Invalid argument: " .. arg)
                    return false
                end
                if parsed[3] == "=" then
                    options.set(parsed[2], value)
                else
                    messages.error("Not implemented yet")
                    return false
                    -- local cur_val = options.get(parsed[2])
                    -- if parsed[3] == "+=" then
                    -- elseif parsed[3] == "^=" then
                    -- elseif parsed[3] == "-=" then
                    -- end
                end
            elseif parsed[1] == "setFalse" then
                if option.typ ~= enums.TYPE_BOOLEAN then
                    messages.error("Invalid argument: " .. arg)
                    return false
                end
                options.set(parsed[2], false)
            elseif parsed[1] == "bare" then
                if option.typ == enums.TYPE_BOOLEAN then
                    options.set(parsed[2], true)
                else
                    messages.echo(parsed[2] .. "=" .. options.get(parsed[2]))
                end
            elseif parsed[1] == "setDefault" then
                messages.error("Not implemented yet")
                return false
            elseif parsed[1] == "show" then
                if option.typ == enums.TYPE_BOOLEAN then
                    if options.get(parsed[2]) then
                        messages.echo(option.aliases[1])
                    else
                        messages.echo("no" .. option.aliases[1])
                    end
                else
                    messages.echo(parsed[2] .. "=" .. options.get(parsed[2]))
                end
            elseif parsed[1] == "invert" then
                if option.typ ~= enums.TYPE_BOOLEAN then
                    messages.error("Invalid argument: " .. arg)
                    return false
                end
                options.set(parsed[2], not options.get(parsed[2]))
            end
        end
        return true
    end
})

registerCommand({
    aliases = {"source", "so"},
    default_range = "",
    range_handler = range_handlers.none,
    execute = function(self, invoc)
        if invoc.exclamation then
            messages.error("Not implemented yet")
            return true
        end
        return mod.runFile(invoc.args[1])
    end
})

registerCommand({
    aliases = {"highlight", "hi"},
    execute = function(self, invoc)
        if #invoc.args == 0 then
            messages.error("Not implemented yet")
            return false
        end
        if invoc.args[1] == "clear" then
            if invoc.args[2] == nil then
                colors.colorscheme = {}
            else
                colors.colorscheme[invoc.args[2]] = nil
            end
            return true
        end
        if invoc.args[1] == "default" then
            messages.error("Default not implemented yet")
            return true
        end

        if invoc.args[1] == "link" then
            if #invoc.args < 3 then
                messages.error("Not enough arguments")
                return false
            elseif #invoc.args > 3 then
                messages.error("Too many arguments")
                return false
            end

            local group = invoc.args[2]
            if colors.colorscheme[group] == nil then
                colors.colorscheme[group] = {}
            end
            for k, _ in pairs(colors.colorscheme[group]) do
                if k ~= "link" then
                    messages.error("group has settings, highlight link ignored.")
                    return false
                end
            end
            colors.colorscheme[group].link = invoc.args[3]
            return true
        end

        local group = invoc.args[1]
        local attribs = {}
        local valid_arguments = {
            term = tostring,
            cterm = tostring,
            ctermfg = tonumber,
            ctermbg = tonumber,
            gui = tostring,
            guifg = tonumber,
            guibg = tonumber,
            guisp = tonumber
        }
        if #invoc.args == 1 then
            messages.error("Not implemented yet.")
            return false
        end
        for i=2, #invoc.args do
            local split = util.split(invoc.args[i], "=")
            if #split == 1 then
                messages.error("Missing equal sign: " .. invoc.args[i])
                return false
            elseif #split == 2 then
                if split[1] == "" then
                    messages.error("Unexpected equal sign: " .. invoc.args[i])
                    return false
                elseif split[2] == "" then
                    messages.error("Missing argument: " .. invoc.args[i])
                    return false
                end
                if valid_arguments[split[1]] then
                    attribs[split[1]] = valid_arguments[split[1]](split[2])
                    if attribs[split[1]] == nil then
                        attribs[split[1]] = colors.color_ids[string.lower(split[2])]
                    end
                else
                    messages.error("Illegal argument: " .. invoc.args[i])
                    return false
                end
            else
                messages.error("Illegal argument: " .. invoc.args[i])
                return false
            end
        end

        if colors.colorscheme[group] == nil then
            colors.colorscheme[group] = {}
        elseif colors.colorscheme[group].link ~= nil then
            colors.colorscheme[group].link = nil
        end

        for key, value in pairs(attribs) do
            colors.colorscheme[group][key] = value
        end
        return true
    end
})

function mod.runFile(filename)
    local f = io.open(filename, "r")

    while true do
        local line = f:read()
        if line == nil then
            break
        end
        if line ~= "" then
            local result = mod.execute(line)
            if result == false then
                f:close()
                return false
            end
        end
    end

    f:close()
    return true
end

function mod.execute(input)
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
    local cmd = commands[stripped_command]
    if cmd ~= nil then
        range = range or {{cmd.default_range, 0}}
        local parsed_range, err = cmd.range_handler(range, window)
        if parsed_range == nil then
            messages.error(err)
            return
        end
        table.remove(split, 1)
        local invocation = Invocation.new(parsed_range, exclamation, split, command)
        return cmd:execute(invocation)
    else
        messages.error("Not an editor command: " .. stripped_command)
    end
end

return mod
