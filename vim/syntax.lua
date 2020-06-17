local util = require("vim/util")

local mod = {}

mod.keywords = {}

function mod.addKeyword(group, keyword, options)
    mod.keywords[#mod.keywords + 1] = {group=group, keyword=keyword, options=options}
end

local function getKeyword(word)
    -- TODO: binary search and profiling
    for _, kw in ipairs(mod.keywords) do
        if kw.keyword == word then
            return kw
        end
    end
    return false
end

local function findWords(line)
    local offset = 0
    local remaining = line
    return function()
        local f_start, f_end = remaining:find("[a-zA-Z][a-zA-Z0-9]*")
        if f_start == nil then
            return nil
        end
        remaining = remaining:sub(f_end + 1)

        local ret1, ret2 = f_start + offset, f_end + offset

        offset = offset + f_end

        return ret1, ret2
    end
end

function mod.parseLine(line)
    local ret = {}
    local start = 1
    for wstart, wend in findWords(line) do
        local word = line:sub(wstart, wend)
        local kw = getKeyword(word)
        if kw then
            ret[#ret + 1] = {"Normal", line:sub(start, wstart - 1)}
            ret[#ret + 1] = {kw.group, word}
            start = wend + 1
        end
    end
    ret[#ret + 1] = {"Normal", line:sub(start, #line)}
    return ret
end

return mod
