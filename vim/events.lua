local event = require("event")
local keyboard = require("keyboard")

local mod = {}

mod.KeyboardEvent = {}
local KeyboardEvent = mod.KeyboardEvent
KeyboardEvent.__index = KeyboardEvent

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

function KeyboardEvent:isPrintable()
    if self.ctrl or self.alt then
        return false
    end
    return self.charcode >= 32 and self.charcode <= 126
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
    return self.charcode == 27 or event.charcode == 0 and event.keycode == keyboard.keys.f1
end

function KeyboardEvent:toVimSyntax()
    local char_lookup = {
        ["<"] = "<LT>",
        [">"] = "<GT>"
    }
    if char_lookup[self.char] then
        return char_lookup[self.char]
    end
    if self:isPrintable() then
        return self.char
    end
    if self:isEscape() then
        return "<ESC>"
    end
    if self:isReturn() then
        return "<RET>"
    end
    if self.char == "\b" then
        return "<BS>"
    end
    return ""
end

function mod.pull()
    while true do
        local ev = {event.pull()}
        if ev[1] == "key_down" then
            return KeyboardEvent.new(ev[3], ev[4])
        end
    end
end

return mod
