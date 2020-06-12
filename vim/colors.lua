local component = require("component")
local gpu = component.gpu

local colors = require("colors")

local util = require("vim/util")

local mod = {}

mod.default_bg = {gpu.getBackground()}
mod.default_fg = {gpu.getForeground()}

mod.palette_colors = {
    [0] = colors.black,
    [1] = colors.blue,
    [2] = colors.green,
    [3] = colors.cyan,
    [4] = colors.red,
    [5] = colors.purple,
    [6] = colors.brown,
    [7] = colors.silver,
    [8] = colors.gray,
    [9] = colors.lightblue,
    [10] = colors.lime,
    [11] = colors.pink,
    [12] = colors.orange,
    [13] = colors.magenta,
    [14] = colors.yellow,
    [15] = colors.white
}

mod.rgb_colors = {
    [0] = 0x000000,
    [1] = 0x333399,
    [2] = 0x336600,
    [3] = 0x336699,
    [4] = 0xff3333,
    [5] = 0x9933cc,
    [6] = 0x663300,
    [7] = 0xcccccc,
    [8] = 0x333333,
    [9] = 0x6699ff,
    [10] = 0x33cc33,
    [11] = 0xff6699,
    [12] = 0xffcc33,
    [13] = 0xcc66cc,
    [14] = 0xffff33,
    [15] = 0xffffff
}

mod.color_names = {
    [0] = "black",
    [1] = "darkred",
    [2] = "darkgreen",
    [3] = "darkyellow",
    [4] = "darkblue",
    [5] = "darkmagenta",
    [6] = "darkcyan",
    [7] = "lightgrey",
    [8] = "darkgrey",
    [9] = "red",
    [10] = "green",
    [11] = "yellow",
    [12] = "blue",
    [13] = "magenta",
    [14] = "cyan",
    [15] = "white"
}

mod.color_ids = {
    black       = 0,
    darkred     = 1,
    darkgreen   = 2,
    brown       = 3,
    darkyellow  = 3,
    darkblue    = 4,
    darkmagenta = 5,
    darkcyan    = 6,
    lightgray   = 7,
    lightgrey   = 7,
    gray        = 7,
    grey        = 7,
    darkgray    = 8,
    darkgrey    = 8,
    red         = 9,
    lightred    = 9,
    green       = 10,
    lightgreen  = 10,
    yellow      = 11,
    lightyellow = 11,
    blue        = 12,
    lightblue   = 12,
    magenta     = 13,
    lightmagenta= 13,
    cyan        = 14,
    lightcyan   = 14,
    white       = 15
}

for i=0, 15 do
    mod.color_ids[mod.color_names[i]] = i
end

mod.default_colorscheme = {
    SpecialKey        = {ctermfg=12},
    EndOfBuffer       = {link="NonText"},
    NonText           = {ctermfg=12},
    Directory         = {ctermfg=14},
    ErrorMsg          = {ctermfg=15, ctermbg=1},
    IncSearch         = {term="reverse", cterm="reverse"},
    Search            = {term="reverse", ctermfg=0, ctermbg=11},
    MoreMsg           = {ctermfg=10},
    LineNr            = {ctermfg=11},
    CursorLineNr      = {ctermfg=11},
    Question          = {ctermfg=10},
    StatusLine        = {term="reverse", cterm="reverse"},
    StatusLineNC      = {term="reverse", cterm="reverse"},
    VertSplit         = {term="reverse", cterm="reverse"},
    Title             = {ctermfg=13},
    Visual            = {term="reverse", ctermbg=8},
    WarningMsg        = {ctermfg=9},
    WildMenu          = {ctermfg=0, ctermbg=11},
    Folded            = {ctermfg=14, ctermbg=8},
    FoldColumn        = {ctermfg=14, ctermbg=8},
    DiffAdd           = {ctermbg=4},
    DiffChange        = {ctermbg=5},
    DiffDelete        = {ctermfg=12, ctermbg=6},
    DiffText          = {term="reverse", ctermbg=9},
    SignColumn        = {ctermfg=14, ctermbg=8},
    Conceal           = {ctermfg=7, ctermbg=8},
    SpellBad          = {term="reverse", ctermbg=9,},
    SpellCap          = {term="reverse", ctermbg=12},
    SpellRare         = {term="reverse", ctermbg=13},
    SpellLocal        = {ctermbg=14},
    Pmenu             = {ctermfg=0, ctermbg=13},
    PmenuSel          = {ctermfg=8, ctermbg=0},
    PmenuSbar         = {ctermbg=7},
    PmenuThumb        = {ctermbg=15},
    TabLine           = {ctermfg=15, ctermbg=8},
    TabLineFill       = {term="reverse", cterm="reverse"},
    CursorColumn      = {term="reverse", ctermbg=8},
    ColorColumn       = {ctermbg=1},
    QuickFixLine      = {link="Search"},
    StatusLineTerm    = {term="reverse", ctermfg=0, ctermbg=10},
    StatusLineTermNC  = {term="reverse", ctermfg=0, ctermbg=10},
    MatchParen        = {term="reverse", ctermbg=6},
    ToolbarLine       = {ctermbg=8},
    ToolbarButton     = {ctermfg=0, ctermbg=7},
    Comment           = {ctermfg=14},
    Constant          = {ctermfg=13},
    Special           = {ctermfg=9},
    Identifier        = {ctermfg=14},
    Statement         = {ctermfg=11},
    PreProc           = {ctermfg=12},
    Type              = {ctermfg=10},
    Underlined        = {ctermfg=12},
    Ignore            = {ctermfg=0},
    Error             = {term="reverse", ctermfg=15, ctermbg=9},
    Todo              = {ctermfg=0, ctermbg=11},
    Cursor            = {term="reverse", cterm="reverse"},
    String            = {link="Constant"},
    Character         = {link="Constant"},
    Number            = {link="Constant"},
    Boolean           = {link="Constant"},
    Float             = {link="Number"},
    Function          = {link="Identifier"},
    Conditional       = {link="Statement"},
    Repeat            = {link="Statement"},
    Label             = {link="Statement"},
    Operator          = {link="Statement"},
    Keyword           = {link="Statement"},
    Exception         = {link="Statement"},
    Include           = {link="PreProc"},
    Define            = {link="PreProc"},
    Macro             = {link="PreProc"},
    PreCondit         = {link="PreProc"},
    StorageClass      = {link="Type"},
    Structure         = {link="Type"},
    Typedef           = {link="Type"},
    Tag               = {link="Special"},
    SpecialChar       = {link="Special"},
    Delimiter         = {link="Special"},
    SpecialComment    = {link="Special"},
    Debug             = {link="Special"},
    Normal            = {ctermfg=15, ctermbg=0},
}

mod.colorscheme = {}

local function resolveLinks(color, col)
    if color == nil then
        return nil
    end
    local visited = {}
    while color.link do
        if visited[color.link] then
            return nil
        end
        visited[color.link] = true
        local new_color = mod.colorscheme[color.link]
        if new_color == nil then
            new_color = mod.default_colorscheme[color.link]
        end
        if new_color == nil then
            return nil
        end
        color = new_color
    end
    return color
end

local function getNormal()
    local color = resolveLinks(mod.colorscheme["Normal"])
    if color == nil then
        color = resolveLinks(mod.default_colorscheme["Normal"])
    end
    if color ~= nil then
        return color
    end
    return {ctermfg=15, ctermbg=0}
end

local function getColor(color)
    if mod.colorscheme[color] then
        local resolved = resolveLinks(mod.colorscheme[color])
        if resolved then return resolved end
    end
    if mod.default_colorscheme[color] then
        local resolved = resolveLinks(mod.default_colorscheme[color], color)
        if resolved then return resolved end
    end
    return getNormal()
end

local function ansiToPalette(color)
    local standards = {
        [0] = colors.black,
        [1] = colors.red,
        [2] = colors.green,
        [3] = colors.brown,
        [4] = colors.blue,
        [5] = colors.purple,
        [6] = colors.cyan,
        [7] = colors.silver,
        [8] = colors.gray,
        [9] = colors.orange,
        [10] = colors.lime,
        [11] = colors.yellow,
        [12] = colors.lightblue,
        [13] = colors.magenta,
        [14] = colors.pink,
        [15] = colors.white
    }
    return standards[color]
end

local function ansiToRgb(color)
    if color < 16 then
        local standards = {
            0x000000, 0x800000, 0x008000, 0x808000, 0x000080, 0x800080, 0x008080, 0xc0c0c0,
            0x808080, 0xff0000, 0x00ff00, 0xffff00, 0x0000ff, 0xff00ff, 0x00ffff, 0xffffff
        }
        return standards[color + 1]
    elseif color >= 16 and color <= 231 then
        local idx = color - 16
        local red = math.floor(idx / 36) * (255 / 5)
        local green = math.floor((idx % 36) / 6) * (255 / 5)
        local blue = (idx % 6) * (255 / 5)
        local rgb = bit32.lshift(red, 16) + bit32.lshift(green, 8) + blue
        return rgb
    else
        local step = 255 / 24
        local value = (color - 232) * step
        local rgb = bit32.lshift(value, 16) + bit32.lshift(value, 8) + value
        return rgb
    end
end

function mod.setColor(colorname)
    local color = getColor(colorname)

    local normal = getNormal()
    if color == nil then
        color = normal
    end

    local fg = color.ctermfg or normal.ctermfg or 15
    local bg = color.ctermbg or normal.ctermbg or 0

    local options = {}
    do
        local optionstring = color.cterm
        if gpu.getDepth() == 1 then
            optionstring = color.term
        end
        local split = util.split(optionstring or "", ",")
        for _, option in ipairs(split) do
            options[option] = true
        end
    end

    if options["inverse"] or options["reverse"] then
        fg, bg = bg, fg
    end

    if gpu.getDepth() == 1 then
        -- Black&White
        if options["inverse"] or options["reverse"] then
            gpu.setBackground(1, false)
            gpu.setForeground(0, false)
        else
            gpu.setBackground(0, false)
            gpu.setForeground(1, false)
        end
    elseif gpu.getDepth() == 4 then
        -- Palette
        local bg_idx = ansiToPalette(bg) or 15
        local fg_idx = ansiToPalette(fg) or 0
        gpu.setBackground(bg_idx, true)
        gpu.setForeground(fg_idx, true)
    else
        -- RGB
        gpu.setBackground(ansiToRgb(bg), false)
        gpu.setForeground(ansiToRgb(fg), false)
    end
end

return mod
