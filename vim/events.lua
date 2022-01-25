local event = require("event")
local keyboard = require("keyboard")

local mod = {}

mod.KeyboardEvent = {}
local KeyboardEvent = mod.KeyboardEvent
KeyboardEvent.__index = KeyboardEvent

mod.simulated_events = {}

function KeyboardEvent.new(charcode, keycode)
    local ret = setmetatable({}, KeyboardEvent)

    ret.charcode = charcode
    ret.keycode = keycode
    ret.char = string.char(charcode)
    ret.keyname = keyboard.keys[keycode]

    ret.ctrl = keyboard.isControlDown() or false
    ret.alt = keyboard.isAltDown() or false
    ret.shift = keyboard.isShiftDown() or false

    ret.printable = charcode >= 32 and charcode <=126

    return ret
end

local function inPrintableRange(charcode)
    return charcode >= 32 and charcode <= 126
end

function KeyboardEvent:isPrintable()
    if self.ctrl then
        return false
    end
    return inPrintableRange(self.charcode)
end

function KeyboardEvent:isModifier()
    return self.keycode == keyboard.keys.lshift
        or self.keycode == keyboard.keys.rshift
        or self.keycode == keyboard.keys.lcontrol
        or self.keycode == keyboard.keys.rcontrol
        or self.keycode == keyboard.keys.lmenu
        or self.keycode == keyboard.keys.rmenu
end

function KeyboardEvent:isReturn()
    return self.char == "\r" or self.char == "\n"
end

function KeyboardEvent:isEscape()
    return self.charcode == 27 or self.charcode == 0 and self.keycode == keyboard.keys.f1
end

function KeyboardEvent:vimSyntaxInner()
    local char_lookup = {
        ["<"] = "LT",
        [">"] = "GT",
        ["\b"] = "BS"
    }
    if char_lookup[self.char] then
        return char_lookup[self.char]
    end
    local prefix = ""
    if self.shift then
        prefix = "S-"
    end
    -- if self.alt then
    --     prefix = "M-" .. prefix
    -- end
    if self:isEscape() then
        return prefix .. "ESC"
    end
    if self:isReturn() then
        return prefix .. "RET"
    end
    if self.char == "\b" then
        return prefix .. "BS"
    end

    prefix = ""
    if self.ctrl then
        prefix = "C-" .. prefix
    end
    -- if self.alt then
    --     prefix = "M-" .. prefix
    -- end

    local char = self.char
    if not inPrintableRange(self.charcode) then
        char = keyboard.keys[self.keycode]
        if char == nil or #char > 1 then
            return ""
        end
    end

    return prefix .. char
end

function KeyboardEvent:toVimSyntax()
    if self:isPrintable() then
        return self.char
    end
    local inner = self:vimSyntaxInner()
    return inner and "<" .. inner .. ">" or ""
end

function mod.simulate(ev)
    mod.simulated_events[#mod.simulated_events + 1] = ev
end

function mod.pull()
    if #mod.simulated_events > 0 then
        return table.remove(mod.simulated_events, 1)
    end
    while true do
        local ev = {event.pull()}
        if ev[1] == "key_down" then
            return KeyboardEvent.new(ev[3], ev[4])
        end
    end
end

return mod
