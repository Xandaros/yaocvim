local enums = require("vim/enums")
local parser = require("vim/parser")
local tabs = require("vim/tabs")
local util = require("vim/util")

local Parser = parser.Parser
local Tab = tabs.Tab

local mod = {}

mod.options = {}

mod.Option = {
    aliases = {},
    locality = enums.LOCALITY_GLOBAL,
    typ = enums.TYPE_BOOLEAN,
    default_value = false
}
local Option = mod.Option
Option.__index = Option

local function getOptionTable(option)
    local tab = Tab.getCurrent()
    local window = tab:getWindow()
    local buffer = window.buffer
    local ret = nil
    if option.locality == enums.LOCALITY_TAB then
        ret = tab.options
    elseif option.locality == enums.LOCALITY_WINDOW then
        ret = window.options
    elseif option.locality == enums.LOCALITY_BUFFER then
        ret = buffer.options
    end
    return ret
end

function mod.set(option, value)
    local obj = mod.options[option]
    if not obj then
        return false
    end
    if obj.locality == enums.LOCALITY_GLOBAL then
        obj.value = value
    else
        getOptionTable(obj)[obj.aliases[1]] = value
    end
end

function mod.get(option)
    local obj = mod.options[option]
    if not obj then
        return nil
    end
    local ret
    if obj.locality == enums.LOCALITY_GLOBAL then
        ret = obj.value
    else
        ret = getOptionTable(obj)[obj.aliases[1]]
    end

    if ret == nil then
        return obj.default_value
    end
    return ret
end

function mod.isValid(option)
    return mod.options[option] and true or false
end

function mod.getOption(option)
    return mod.options[option]
end

do
    local function mktbl(first)
        return function(second)
            return {first, second}
        end
    end
    local name = Parser.many1(Parser.letter())
    local value = Parser.many(Parser.satisfy(function(x) return not x:match("%s") end))
    local operator = Parser.string("=")
        + Parser.string(":"):map(util.const("="))
        + Parser.string("+=")
        + Parser.string("^=")
        + Parser.string("-=")
    local invert = (Parser.string("inv") * name) + (name - Parser.string("!"))
    local setFalse = Parser.string("no") * name
    local setDefault = name - Parser.string("&")
    local showValue = name - Parser.string("?")
    local changedValue = name:andThen(function(pname)
        return operator:andThen(function(poperator)
            return value:andThen(function(pvalue)
                return Parser.pure({"change", pname, poperator, pvalue})
            end)
        end)
    end)
    mod.optionparser = (invert:map(mktbl("invert"))
        + setFalse:map(mktbl("setFalse"))
        + setDefault:map(mktbl("setDefault"))
        + showValue:map(mktbl("show"))
        + changedValue
        + name:map(mktbl("bare"))) - Parser.eof()
end

local function registerOption(optionspec)
    setmetatable(optionspec, Option)
    optionspec.value = optionspec.default_value
    for _, alias in ipairs(optionspec.aliases) do
        mod.options[alias] = optionspec
    end
end

registerOption({
    aliases = {"hidden", "hid"},
    default_value = false
})

registerOption({
    aliases = {"test"},
    default_value = "asd",
    typ = enums.TYPE_STRING
})

return mod
