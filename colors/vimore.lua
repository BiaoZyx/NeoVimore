-- ============================================================
-- Vimore 配色（:colorscheme vimore）
-- 深海墨色背景 + 哑光多巴胺语法色，不依赖任何外部主题
-- ============================================================

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then vim.cmd('syntax reset') end

vim.g.colors_name = 'vimore'

local c = vim.api.nvim_set_hl

-- ---------- 调色板 ----------
-- 背景层级：基于表面高程（Elevation），通过明度差异构建空间深度
local bg0 = '#121217' -- 主画布（深海墨色）
local bg1 = '#1a1a22' -- 轻微抬升（CursorLine, LineNr, Sidebar）
local bg2 = '#22222c' -- 浮动表面（Pmenu, NormalFloat, 悬浮提示）
local bg3 = '#2c2c38' -- 高亮表面（StatusLine, Visual, TabLineSel）
local bg4 = '#3e3e4c' -- 边框与分割线

-- 前景层级：低眩光文本（使用带灰度的浅色）
local fg0 = '#d4d4dc' -- 主文本
local fg1 = '#a0a0b0' -- 次要文本
local fg2 = '#6c6c7e' -- 注释、行号、非核心信息
local fg3 = '#454552' -- 极暗元素（如不可见字符）

-- 结构专用色：比 fg2 更暗，让标点符号退居幕后
local punct = '#5b5b6d'

-- 语义高亮色：哑光多巴胺
local red = '#e5748a'
local orange = '#e8a77d'
local yellow = '#d6bc84'
local green = '#82c79a'
local cyan = '#82c4d4'
local blue = '#7fa9de'
local purple = '#b39fe0'

-- 把 hex 颜色折算成最接近的 xterm-256 色号，供 termguicolors=false 时使用
local levels = { 0, 95, 135, 175, 215, 255 }
local function hex_to_cterm(hex)
    if type(hex) ~= 'string' or not hex:match('^#%x%x%x%x%x%x$') then return hex end
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    local best, best_dist = 0, math.huge
    for i = 0, 5 do
        for j = 0, 5 do
            for k = 0, 5 do
                local dr, dg, db = levels[i + 1] - r, levels[j + 1] - g, levels[k + 1] - b
                local d = dr * dr + dg * dg + db * db
                if d < best_dist then
                    best_dist = d
                    best = 16 + 36 * i + 6 * j + k
                end
            end
        end
    end
    for i = 0, 23 do
        local v = 8 + 10 * i
        local d = (v - r) ^ 2 + (v - g) ^ 2 + (v - b) ^ 2
        if d < best_dist then
            best_dist = d
            best = 232 + i
        end
    end
    return best
end

-- 同时写入 GUI 与 256 色属性；真彩终端用 hex，其它终端用折算后的色号
local function set(groups)
    for name, spec in pairs(groups) do
        local s = vim.deepcopy(spec)
        if s.fg then s.ctermfg = hex_to_cterm(s.fg) end
        if s.bg then s.ctermbg = hex_to_cterm(s.bg) end
        -- nvim_set_hl 的 cterm 是样式布尔表，颜色用 ctermfg/ctermbg
        local ct = {}
        if s.bold then ct.bold = true end
        if s.italic then ct.italic = true end
        if s.underline or s.undercurl then ct.underline = true end
        if s.strikethrough then ct.strikethrough = true end
        if next(ct) then s.cterm = ct end
        c(0, name, s)
    end
end

-- ---------- 基础 UI ----------
set({
    Normal = { fg = fg0, bg = bg0 },
    NormalNC = { fg = fg0, bg = bg0 },
    NormalFloat = { fg = fg0, bg = bg2 },
    FloatBorder = { fg = bg4, bg = bg2 },
    FloatTitle = { fg = yellow, bg = bg2, bold = true },
    FloatFooter = { fg = fg2, bg = bg2 },

    LineNr = { fg = fg3, bg = bg0 },
    CursorLineNr = { fg = yellow, bg = bg1, bold = true },
    CursorLine = { bg = bg1, nocombine = true },
    CursorColumn = { bg = bg1 },
    Cursor = { fg = bg0, bg = fg0 },
    lCursor = { fg = bg0, bg = fg0 },
    TermCursor = { fg = bg0, bg = fg0 },

    SignColumn = { fg = fg3, bg = bg0 },
    -- 光标所在行连符号列/折叠列一起高亮，左侧 gutter 不会断一截
    CursorLineSign = { fg = fg3, bg = bg1 },
    CursorLineFold = { fg = fg3, bg = bg1 },
    ColorColumn = { bg = bg1 },
    VertSplit = { fg = bg4, bg = bg0 },
    WinSeparator = { fg = bg4, bg = bg0 },

    Visual = { bg = bg3 },
    VisualNOS = { bg = bg2 },

    Search = { fg = bg0, bg = yellow },
    IncSearch = { fg = bg0, bg = yellow, bold = true },
    CurSearch = { fg = bg0, bg = yellow, bold = true },
    MatchParen = { fg = cyan, bold = true, underline = true },

    Pmenu = { fg = fg0, bg = bg2 },
    PmenuSel = { fg = bg0, bg = purple, bold = true },
    PmenuSbar = { bg = bg1 },
    PmenuThumb = { bg = bg4 },
    PmenuKind = { fg = yellow, bg = bg2 },
    PmenuExtra = { fg = fg2, bg = bg2 },
    PmenuMatch = { fg = blue, bg = bg2 },
    PmenuMatchSel = { fg = bg0, bg = purple, bold = true },

    StatusLine = { fg = fg0, bg = bg3, bold = true },
    StatusLineNC = { fg = fg2, bg = bg1 },
    StatusLineTerm = { fg = fg0, bg = bg3, bold = true },
    StatusLineTermNC = { fg = fg2, bg = bg1 },

    MsgArea = { fg = fg0, bg = bg0 },
    MsgSeparator = { fg = bg4, bg = bg0 },
    WildMenu = { fg = bg0, bg = purple, bold = true },
    QuickFixLine = { bg = bg2, bold = true },

    TabLine = { fg = fg2, bg = bg1 },
    TabLineSel = { fg = fg0, bg = bg3, bold = true },
    TabLineFill = { bg = bg1 },

    NonText = { fg = bg4 },
    SpecialKey = { fg = bg4 },
    Whitespace = { fg = punct }, -- listchars 的 · 用这个颜色
    -- 行尾空格实际由 listchars 的 · 显示；保留这个组供旧脚本用
    ExtraWhitespace = { fg = punct },
    Conceal = { fg = fg2 },
    Directory = { fg = blue, bold = true },
    Title = { fg = yellow, bold = true },
    ErrorMsg = { fg = red, bold = true },
    WarningMsg = { fg = yellow, bold = true },
    MoreMsg = { fg = green, bold = true },
    Question = { fg = green },
    ModeMsg = { fg = fg0, bold = true },

    Folded = { fg = fg2, bg = bg1 },
    FoldColumn = { fg = fg3, bg = bg0 },

    DiffAdd = { fg = green, bg = bg1 },
    DiffChange = { fg = yellow, bg = bg1 },
    DiffDelete = { fg = red, bg = bg1 },
    DiffText = { fg = blue, bg = bg2, bold = true },
})

-- ---------- 用户自定义 UI 段 ----------
set({
    User1 = { fg = yellow, bg = bg3, bold = true },
    User2 = { fg = green, bg = bg3, bold = true },
    User3 = { fg = blue, bg = bg3, bold = true },
    User4 = { fg = purple, bg = bg3, bold = true },
    User5 = { fg = cyan, bg = bg3, bold = true },

    ModeNormal = { fg = fg0, bg = bg3, bold = true },
    ModeInsert = { fg = blue, bg = bg3, bold = true },
    ModeVisual = { fg = green, bg = bg3, bold = true },
    ModeVLine = { fg = cyan, bg = bg3, bold = true },
    ModeVBlock = { fg = purple, bg = bg3, bold = true },
    ModeReplace = { fg = red, bg = bg3, bold = true },
    ModeCmdline = { fg = yellow, bg = bg3, bold = true },
    ModeTerminal = { fg = orange, bg = bg3, bold = true },
})

-- ---------- 基础语法高亮 ----------
set({
    Comment = { fg = fg2, italic = true },
    Constant = { fg = yellow },
    String = { fg = green },
    Character = { fg = green },
    Number = { fg = yellow },
    Boolean = { fg = yellow },
    Float = { fg = yellow },

    Identifier = { fg = fg0 },
    Function = { fg = blue },

    Statement = { fg = purple, bold = true },
    Conditional = { fg = purple, bold = true },
    Repeat = { fg = purple, bold = true },
    Keyword = { fg = purple, bold = true },
    Exception = { fg = purple, bold = true },

    PreProc = { fg = purple },
    Include = { fg = purple },
    Define = { fg = purple },
    Macro = { fg = orange },
    PreCondit = { fg = purple },

    Type = { fg = yellow },
    StorageClass = { fg = yellow },
    Structure = { fg = yellow },
    Typedef = { fg = yellow },

    Special = { fg = cyan },
    SpecialChar = { fg = cyan },
    Tag = { fg = red },
    Delimiter = { fg = punct },
    Operator = { fg = blue }, -- 含 C 的指针 *，统一用蓝色
    SpecialComment = { fg = cyan, italic = true },
    Debug = { fg = red },

    Underlined = { fg = blue, underline = true },
    Ignore = { fg = fg3 },
    Error = { fg = red, bold = true },
    Todo = { fg = yellow, bold = true, italic = true },
})

-- ---------- Treesitter 节点高亮 ----------
-- 只有在 :lua vim.treesitter.start() 或装了 treesitter 插件时才生效；
-- 没有 treesitter 时这些组不会被使用，保留是为了开箱即用的主题一致性。
set({
    ['@variable'] = { fg = fg0 },
    ['@variable.parameter'] = { fg = orange },
    ['@variable.builtin'] = { fg = red, italic = true },
    ['@variable.member'] = { fg = red },

    ['@constant'] = { fg = yellow },
    ['@constant.builtin'] = { fg = yellow, italic = true },
    ['@constant.macro'] = { fg = orange },

    ['@string'] = { fg = green },
    ['@string.escape'] = { fg = cyan },
    ['@string.special'] = { fg = cyan },
    ['@string.regexp'] = { fg = cyan },

    ['@number'] = { fg = yellow },
    ['@boolean'] = { fg = yellow },
    ['@float'] = { fg = yellow },

    ['@function'] = { fg = blue },
    ['@function.builtin'] = { fg = blue, italic = true },
    ['@function.call'] = { fg = blue },
    ['@function.macro'] = { fg = orange },
    ['@method'] = { fg = blue },
    ['@method.call'] = { fg = blue },
    ['@constructor'] = { fg = yellow },

    ['@keyword'] = { fg = purple, bold = true },
    ['@keyword.function'] = { fg = purple, bold = true },
    ['@keyword.return'] = { fg = purple, bold = true },
    ['@conditional'] = { fg = purple, bold = true },
    ['@repeat'] = { fg = purple, bold = true },
    ['@exception'] = { fg = purple, bold = true },

    ['@operator'] = { fg = blue }, -- 含指针 *，统一蓝色

    ['@type'] = { fg = yellow },
    ['@type.builtin'] = { fg = yellow, italic = true },
    ['@type.definition'] = { fg = yellow },
    ['@namespace'] = { fg = yellow },

    ['@parameter'] = { fg = orange },
    ['@property'] = { fg = red },
    ['@field'] = { fg = red },

    ['@comment'] = { fg = fg2, italic = true },
    ['@comment.documentation'] = { fg = fg2, italic = true },

    ['@punctuation.delimiter'] = { fg = punct },
    ['@punctuation.bracket'] = { fg = punct },
    ['@punctuation.special'] = { fg = cyan },

    ['@tag'] = { fg = red },
    ['@tag.attribute'] = { fg = orange },
    ['@tag.delimiter'] = { fg = punct },

    ['@markup.heading'] = { fg = yellow, bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.bold'] = { bold = true },
    ['@markup.link'] = { fg = blue, underline = true },
    ['@markup.raw'] = { fg = green },
})

-- lua-language-server 会把整块注释标记成 keyword + documentation 语义 token，
-- 它会覆盖 treesitter 的 comment 色，让 @file / @author 变成紫色粗体。
-- 把这些语义 token 改回注释色，等几秒后再刷新也不会变色。
set({
    ['@lsp.type.keyword.lua'] = { fg = fg2, italic = true },
    ['@lsp.typemod.keyword.documentation.lua'] = { fg = fg2, italic = true },
    ['@lsp.typemod.keyword.documentation'] = { fg = fg2, italic = true },
})

-- ---------- 诊断 / LSP 悬浮与指示 ----------
set({
    DiagnosticError = { fg = red },
    DiagnosticWarn = { fg = yellow },
    DiagnosticInfo = { fg = blue },
    DiagnosticHint = { fg = cyan },

    DiagnosticVirtualTextError = { fg = red, bg = bg1 },
    DiagnosticVirtualTextWarn = { fg = yellow, bg = bg1 },
    DiagnosticVirtualTextInfo = { fg = blue, bg = bg1 },
    DiagnosticVirtualTextHint = { fg = cyan, bg = bg1 },

    DiagnosticUnderlineError = { undercurl = true, sp = red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = cyan },

    DiagnosticSignError = { fg = red },
    DiagnosticSignWarn = { fg = yellow },
    DiagnosticSignInfo = { fg = blue },
    DiagnosticSignHint = { fg = cyan },

    LspReferenceText = { bg = bg2 },
    LspReferenceRead = { bg = bg2 },
    LspReferenceWrite = { bg = bg2, underline = true },
    LspSignatureActiveParameter = { fg = orange, bold = true },
})

-- ---------- Git 状态标记（给未来装 git 插件的人留好颜色） ----------
set({
    GitSignsAdd = { fg = green },
    GitSignsChange = { fg = yellow },
    GitSignsDelete = { fg = red },
})

-- ---------- 内置终端 16 色映射 ----------
local term_colors = {
    -- 颜色 0 同时被很多程序当作「背景色」，要跟画布一致，否则终端空白处会发灰
    bg0,
    red,
    green,
    yellow,
    blue,
    purple,
    cyan,
    fg0,
    fg3,
    red,
    green,
    yellow,
    blue,
    purple,
    cyan,
    '#ffffff',
}
for i = 0, 15 do
    local value = term_colors[i + 1]
    vim.g['terminal_color_' .. i] = vim.o.termguicolors and value or hex_to_cterm(value)
end
