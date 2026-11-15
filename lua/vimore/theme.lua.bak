-- ============================================================
-- Vimore Dark 配色
-- 冷灰蓝背景 + One Dark 语法色，不依赖任何 colorscheme
-- ============================================================
local M = {}

local c = vim.api.nvim_set_hl

-- ---------- 调色板 ----------
local bg0 = '#1b1e24'   -- 最深，主背景
local bg1 = '#22262e'   -- 次深，CursorLine / LineNr
local bg2 = '#2a2f38'   -- 中等，Pmenu / StatusLineNC
local bg3 = '#343a45'   -- 较亮，StatusLine / TabLineSel / Visual
local bg4 = '#3e4553'   -- 边框、分割线

local fg0 = '#d5dae2'   -- 主文本
local fg1 = '#a3abb8'   -- 次要文本
local fg2 = '#7b8394'   -- 注释、行号
local fg3 = '#5c6370'   -- 更深，非文本

local red    = '#e06c75'
local orange = '#d19a66'
local yellow = '#e5c07b'
local green  = '#98c379'
local cyan   = '#56b6c2'
local blue   = '#61afef'
local purple = '#c678dd'

-- ---------- 批量设置 ----------
local function set(groups)
    for name, spec in pairs(groups) do
        c(0, name, spec)
    end
end

-- ---------- 基础 UI ----------
set({
    Normal       = { fg = fg0, bg = bg0 },
    NormalNC     = { fg = fg0, bg = bg0 },
    NormalFloat  = { fg = fg0, bg = bg1 },
    FloatBorder  = { fg = bg4, bg = bg1 },
    FloatTitle   = { fg = yellow, bg = bg1, bold = true },

    LineNr       = { fg = fg3, bg = bg0 },
    CursorLineNr = { fg = yellow, bg = bg1, bold = true },
    CursorLine   = { bg = bg1, nocombine = true },
    CursorColumn = { bg = bg1 },

    SignColumn   = { fg = fg3, bg = bg0 },
    ColorColumn  = { bg = bg1 },
    VertSplit    = { fg = bg4, bg = bg0 },
    WinSeparator = { fg = bg4, bg = bg0 },

    Visual       = { bg = bg3 },
    VisualNOS    = { bg = bg2 },

    Search       = { fg = bg0, bg = yellow },
    IncSearch    = { fg = bg0, bg = orange, bold = true },
    CurSearch    = { fg = bg0, bg = orange, bold = true },
    MatchParen   = { fg = cyan, bold = true, underline = true },

    Pmenu        = { fg = fg0, bg = bg2 },
    PmenuSel     = { fg = blue, bg = bg3, bold = true },
    PmenuSbar    = { bg = bg1 },
    PmenuThumb   = { bg = bg4 },
    PmenuKind    = { fg = yellow, bg = bg2 },
    PmenuExtra   = { fg = fg2, bg = bg2 },

    StatusLine      = { fg = fg0, bg = bg3, bold = true },
    StatusLineNC    = { fg = fg2, bg = bg1 },
    StatusLineTerm   = { fg = fg0, bg = bg3, bold = true },
    StatusLineTermNC = { fg = fg2, bg = bg1 },

    TabLine     = { fg = fg2, bg = bg1 },
    TabLineSel  = { fg = fg0, bg = bg3, bold = true },
    TabLineFill = { bg = bg1 },

    NonText      = { fg = bg4 },
    SpecialKey   = { fg = bg4 },
    Whitespace   = { fg = bg4 },
    Conceal      = { fg = fg2 },
    Directory    = { fg = blue, bold = true },
    Title        = { fg = yellow, bold = true },
    ErrorMsg     = { fg = red, bold = true },
    WarningMsg   = { fg = yellow, bold = true },
    MoreMsg      = { fg = green, bold = true },
    Question     = { fg = green },
    ModeMsg      = { fg = fg0, bold = true },

    Folded       = { fg = fg2, bg = bg1 },
    FoldColumn   = { fg = fg3, bg = bg0 },

    DiffAdd      = { fg = green, bg = bg1 },
    DiffChange   = { fg = yellow, bg = bg1 },
    DiffDelete   = { fg = red, bg = bg1 },
    DiffText     = { fg = blue, bg = bg2, bold = true },
})

-- ---------- 用户自定义段（状态栏右侧、模式指示器） ----------
set({
    User1 = { fg = yellow, bg = bg3, bold = true },
    User2 = { fg = green,  bg = bg3, bold = true },
    User3 = { fg = blue,   bg = bg3, bold = true },
    User4 = { fg = purple, bg = bg3, bold = true },
    User5 = { fg = cyan,   bg = bg3, bold = true },

    ModeNormal   = { fg = fg0,    bg = bg3, bold = true },
    ModeInsert   = { fg = blue,   bg = bg3, bold = true },
    ModeVisual   = { fg = green,  bg = bg3, bold = true },
    ModeVLine    = { fg = cyan,   bg = bg3, bold = true },
    ModeVBlock   = { fg = purple, bg = bg3, bold = true },
    ModeReplace  = { fg = red,    bg = bg3, bold = true },
    ModeCmdline  = { fg = yellow, bg = bg3, bold = true },
    ModeTerminal = { fg = orange, bg = bg3, bold = true },
})

-- ---------- 基础语法 ----------
set({
    Comment        = { fg = fg2, italic = true },
    Constant       = { fg = orange },
    String         = { fg = green },
    Character      = { fg = green },
    Number         = { fg = orange },
    Boolean        = { fg = orange },
    Float          = { fg = orange },

    Identifier     = { fg = fg0 },
    Function       = { fg = blue },

    Statement      = { fg = purple },
    Conditional    = { fg = purple },
    Repeat         = { fg = purple },
    Label          = { fg = purple },
    Operator       = { fg = cyan },
    Keyword        = { fg = purple },
    Exception      = { fg = purple },

    PreProc        = { fg = purple },
    Include        = { fg = purple },
    Define         = { fg = purple },
    Macro          = { fg = orange },
    PreCondit      = { fg = purple },

    Type           = { fg = yellow },
    StorageClass   = { fg = yellow },
    Structure      = { fg = yellow },
    Typedef        = { fg = yellow },

    Special        = { fg = cyan },
    SpecialChar    = { fg = cyan },
    Tag            = { fg = red },
    Delimiter      = { fg = fg1 },
    SpecialComment = { fg = cyan, italic = true },
    Debug          = { fg = red },

    Underlined = { fg = blue, underline = true },
    Ignore     = { fg = fg3 },
    Error      = { fg = red, bold = true },
    Todo       = { fg = yellow, bold = true, italic = true },
})

-- ---------- Treesitter ----------
set({
    ['@variable']              = { fg = fg0 },
    ['@variable.parameter']    = { fg = orange },
    ['@variable.builtin']      = { fg = red, italic = true },
    ['@variable.member']       = { fg = red },

    ['@constant']              = { fg = orange },
    ['@constant.builtin']      = { fg = orange, italic = true },
    ['@constant.macro']        = { fg = orange },

    ['@string']                = { fg = green },
    ['@string.escape']         = { fg = cyan },
    ['@string.special']        = { fg = cyan },
    ['@string.regexp']         = { fg = cyan },

    ['@number']                = { fg = orange },
    ['@boolean']               = { fg = orange },
    ['@float']                 = { fg = orange },

    ['@function']              = { fg = blue },
    ['@function.builtin']      = { fg = blue, italic = true },
    ['@function.call']         = { fg = blue },
    ['@function.macro']        = { fg = orange },
    ['@method']                = { fg = blue },
    ['@method.call']           = { fg = blue },
    ['@constructor']           = { fg = yellow },

    ['@keyword']               = { fg = purple },
    ['@keyword.function']      = { fg = purple },
    ['@keyword.return']        = { fg = purple },
    ['@keyword.operator']      = { fg = cyan },
    ['@conditional']           = { fg = purple },
    ['@repeat']                = { fg = purple },
    ['@exception']             = { fg = purple },

    ['@operator']              = { fg = cyan },

    ['@type']                  = { fg = yellow },
    ['@type.builtin']          = { fg = yellow, italic = true },
    ['@type.definition']       = { fg = yellow },
    ['@namespace']             = { fg = yellow },

    ['@parameter']             = { fg = orange },
    ['@property']              = { fg = red },
    ['@field']                 = { fg = red },

    ['@comment']               = { fg = fg2, italic = true },
    ['@comment.documentation'] = { fg = fg2, italic = true },

    ['@punctuation.delimiter'] = { fg = fg1 },
    ['@punctuation.bracket']   = { fg = fg1 },
    ['@punctuation.special']   = { fg = cyan },

    ['@tag']                   = { fg = red },
    ['@tag.attribute']         = { fg = orange },
    ['@tag.delimiter']         = { fg = fg1 },

    ['@markup.heading']        = { fg = yellow, bold = true },
    ['@markup.italic']         = { italic = true },
    ['@markup.bold']           = { bold = true },
    ['@markup.link']           = { fg = blue, underline = true },
    ['@markup.raw']            = { fg = green },
})

-- ---------- 诊断 ----------
set({
    DiagnosticError = { fg = red },
    DiagnosticWarn  = { fg = yellow },
    DiagnosticInfo  = { fg = blue },
    DiagnosticHint  = { fg = cyan },

    DiagnosticVirtualTextError = { fg = red,    bg = bg1 },
    DiagnosticVirtualTextWarn  = { fg = yellow, bg = bg1 },
    DiagnosticVirtualTextInfo  = { fg = blue,   bg = bg1 },
    DiagnosticVirtualTextHint  = { fg = cyan,   bg = bg1 },

    DiagnosticUnderlineError = { undercurl = true, sp = red },
    DiagnosticUnderlineWarn  = { undercurl = true, sp = yellow },
    DiagnosticUnderlineInfo  = { undercurl = true, sp = blue },
    DiagnosticUnderlineHint  = { undercurl = true, sp = cyan },

    DiagnosticSignError = { fg = red },
    DiagnosticSignWarn  = { fg = yellow },
    DiagnosticSignInfo  = { fg = blue },
    DiagnosticSignHint  = { fg = cyan },
})

-- ---------- Git 标记（无插件也无害） ----------
set({
    GitSignsAdd    = { fg = green },
    GitSignsChange = { fg = yellow },
    GitSignsDelete = { fg = red },
})

-- ---------- 终端 16 色 ----------
local term_colors = {
    bg4,    red,    green,  yellow,
    blue,   purple, cyan,   fg0,
    fg3,    red,    green,  yellow,
    blue,   purple, cyan,   '#ffffff',
}
for i = 0, 15 do
    vim.g['terminal_color_' .. i] = term_colors[i + 1]
end

-- ---------- 标签栏 ----------
set({
    TabLine     = { fg = fg2, bg = bg1 },
    TabLineSel  = { fg = fg0, bg = bg3, bold = true },
    TabLineFill = { bg = bg1 },
})

-- 标签栏渲染
local function render_tabline()
    local s = ''
    local cur = vim.fn.tabpagenr()
    local total = vim.fn.tabpagenr('$')
    local width = math.floor((vim.o.columns - 2) / total)
    if width < 8 then width = 8 end
    local padding = 2

    for i = 1, total do
        local buflist = vim.fn.tabpagebuflist(i)
        local winnr = vim.fn.tabpagewinnr(i)
        local bufname = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ':t')
        if bufname == '' then bufname = '[No Name]' end

        local name_len = width - #(i .. ':') - 2 - padding
        if #bufname > name_len then
            bufname = bufname:sub(1, name_len - 2) .. '…'
        end

        local modified = vim.bo[buflist[winnr]].modified and '+' or ''
        local label = ' ' .. i .. ':' .. bufname .. modified
        label = label .. string.rep(' ', math.max(0, width - #label))

        if i == cur then
            s = s .. '%#TabLineSel#' .. label
        else
            s = s .. '%#TabLine#' .. label
        end
    end

    return s .. '%#TabLineFill#%T'
end

function M.tabline()
    return render_tabline()
end

vim.o.showtabline = 1
vim.o.tabline = '%!v:lua.require("vimore.theme").tabline()'

return M

