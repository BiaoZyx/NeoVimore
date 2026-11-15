-- ============================================================
-- Vimore Deep 配色
-- ============================================================
local M = {}

local c = vim.api.nvim_set_hl

-- ---------- 调色板 ----------
-- 背景层级：基于表面高程（Elevation），通过明度差异构建空间深度
local bg0 = '#121217'   -- 主画布（深海墨色）
local bg1 = '#1a1a22'   -- 轻微抬升（CursorLine, LineNr, Sidebar）
local bg2 = '#22222c'   -- 浮动表面（Pmenu, NormalFloat, 悬浮提示）
local bg3 = '#2c2c38'   -- 高亮表面（StatusLine, Visual, TabLineSel）
local bg4 = '#3e3e4c'   -- 边框与分割线（与 bg3 接近，用于划分区域）

-- 前景层级：低眩光文本（使用带灰度的浅色）
local fg0 = '#d4d4dc'   -- 主文本
local fg1 = '#a0a0b0'   -- 次要文本
local fg2 = '#6c6c7e'   -- 注释、行号、非核心信息
local fg3 = '#454552'   -- 极暗元素（如不可见字符）

-- 结构专用色：比 fg2 更暗，让标点符号退居幕后，不干扰语义阅读
local punct = '#5b5b6d'

-- 语义高亮色：哑光多巴胺
local red    = '#e5748a'   -- 错误、特殊标记
local orange = '#e8a77d'   -- 参数、部分常量
local yellow = '#d6bc84'   -- 类型、转义符
local green  = '#82c79a'   -- 字符串
local cyan   = '#82c4d4'   -- 特殊字符
local blue   = '#7fa9de'   -- 函数名
local purple = '#b39fe0'   -- 关键字、控制流

-- ---------- 批量设置函数 ----------
local function set(groups)
    for name, spec in pairs(groups) do
        c(0, name, spec)
    end
end

-- ---------- 基础 UI ----------
set({
    Normal       = { fg = fg0, bg = bg0 },
    NormalNC     = { fg = fg0, bg = bg0 },
    NormalFloat  = { fg = fg0, bg = bg2 },
    FloatBorder  = { fg = bg4, bg = bg2 },
    FloatTitle   = { fg = yellow, bg = bg2, bold = true },

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
    IncSearch    = { fg = bg0, bg = yellow, bold = true },
    CurSearch    = { fg = bg0, bg = yellow, bold = true },
    MatchParen   = { fg = cyan, bold = true, underline = true },

    Pmenu        = { fg = fg0, bg = bg2 },
    PmenuSel     = { fg = bg0, bg = purple, bold = true },
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

-- ---------- 用户自定义 UI 段 ----------
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

-- ---------- 基础语法高亮 ----------
set({
    Comment        = { fg = fg2, italic = true },
    Constant       = { fg = yellow },
    String         = { fg = green },
    Character      = { fg = green },
    Number         = { fg = yellow },
    Boolean        = { fg = yellow },
    Float          = { fg = yellow },

    Identifier     = { fg = fg0 },
    Function       = { fg = blue },

    Statement      = { fg = purple },
    Conditional    = { fg = purple },
    Repeat         = { fg = purple },
    Label          = { fg = purple },
    Operator       = { fg = punct },
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
    Delimiter      = { fg = punct },
    SpecialComment = { fg = cyan, italic = true },
    Debug          = { fg = red },

    Underlined = { fg = blue, underline = true },
    Ignore     = { fg = fg3 },
    Error      = { fg = red, bold = true },
    Todo       = { fg = yellow, bold = true, italic = true },
})

-- ---------- Treesitter 节点高亮 ----------
set({
    ['@variable']              = { fg = fg0 },
    ['@variable.parameter']    = { fg = orange },
    ['@variable.builtin']      = { fg = red, italic = true },
    ['@variable.member']       = { fg = red },

    ['@constant']              = { fg = yellow },
    ['@constant.builtin']      = { fg = yellow, italic = true },
    ['@constant.macro']        = { fg = orange },

    ['@string']                = { fg = green },
    ['@string.escape']         = { fg = cyan },
    ['@string.special']        = { fg = cyan },
    ['@string.regexp']         = { fg = cyan },

    ['@number']                = { fg = yellow },
    ['@boolean']               = { fg = yellow },
    ['@float']                 = { fg = yellow },

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
    ['@keyword.operator']      = { fg = punct },
    ['@conditional']           = { fg = purple },
    ['@repeat']                = { fg = purple },
    ['@exception']             = { fg = purple },

    ['@operator']              = { fg = punct },

    ['@type']                  = { fg = yellow },
    ['@type.builtin']          = { fg = yellow, italic = true },
    ['@type.definition']       = { fg = yellow },
    ['@namespace']             = { fg = yellow },

    ['@parameter']             = { fg = orange },
    ['@property']              = { fg = red },
    ['@field']                 = { fg = red },

    ['@comment']               = { fg = fg2, italic = true },
    ['@comment.documentation'] = { fg = fg2, italic = true },

    ['@punctuation.delimiter'] = { fg = punct },
    ['@punctuation.bracket']   = { fg = punct },
    ['@punctuation.special']   = { fg = cyan },

    ['@tag']                   = { fg = red },
    ['@tag.attribute']         = { fg = orange },
    ['@tag.delimiter']         = { fg = punct },

    ['@markup.heading']        = { fg = yellow, bold = true },
    ['@markup.italic']         = { italic = true },
    ['@markup.bold']           = { bold = true },
    ['@markup.link']           = { fg = blue, underline = true },
    ['@markup.raw']            = { fg = green },
})

-- ---------- 诊断 / LSP 悬浮与指示 ----------
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

-- ---------- Git 状态标记 ----------
set({
    GitSignsAdd    = { fg = green },
    GitSignsChange = { fg = yellow },
    GitSignsDelete = { fg = red },
})

-- ---------- 内置终端 16 色映射 ----------
local term_colors = {
    bg4,    red,    green,  yellow,
    blue,   purple, cyan,   fg0,
    fg3,    red,    green,  yellow,
    blue,   purple, cyan,   '#ffffff',
}
for i = 0, 15 do
    vim.g['terminal_color_' .. i] = term_colors[i + 1]
end

-- ---------- 标签栏基础颜色 ----------
set({
    TabLine     = { fg = fg2, bg = bg1 },
    TabLineSel  = { fg = fg0, bg = bg3, bold = true },
    TabLineFill = { bg = bg1 },
})

-- ---------- 标签栏渲染函数 ----------
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
