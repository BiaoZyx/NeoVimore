-- ============================================================
-- 2. 界面显示 / 15. 边界线 / 自定义高亮（状态栏、标签栏、模式指示器）
-- ============================================================
-- Neovim 统一走 true color，原版的 256 色 / 8 色 cterm 分支不再需要
local M = {}

local opt = vim.opt

opt.termguicolors = true

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.showmode = false -- 不显示 --INSERT--（状态栏已显示）
opt.laststatus = 2 -- 始终显示状态栏
opt.ruler = true
opt.title = true

-- 进入插入模式时使用绝对行号，退出时恢复相对行号
local num_group = vim.api.nvim_create_augroup('VimoreNumber', { clear = true })
vim.api.nvim_create_autocmd('InsertEnter', {
    group = num_group,
    callback = function()
        vim.opt.relativenumber = false
        vim.opt.number = true
    end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
    group = num_group,
    callback = function()
        vim.opt.relativenumber = true
    end,
})

-- ---------- 高亮颜色定义 ----------
local c = vim.api.nvim_set_hl

-- 状态栏
c(0, 'StatusLine', { fg = '#ffffff', bg = '#585858', bold = true })
c(0, 'StatusLineNC', { fg = '#aaaaaa', bg = '#303030' })
-- 终端窗口的状态栏（Neovim 在 terminal buffer 上自动使用）
c(0, 'StatusLineTerm', { fg = '#ffffff', bg = '#585858', bold = true })
c(0, 'StatusLineTermNC', { fg = '#aaaaaa', bg = '#303030' })
c(0, 'User1', { fg = '#ffd700', bg = '#585858', bold = true })
c(0, 'User2', { fg = '#87d787', bg = '#585858', bold = true })
c(0, 'User3', { fg = '#5fd7ff', bg = '#585858', bold = true })
c(0, 'User4', { fg = '#d7afff', bg = '#585858', bold = true })
c(0, 'User5', { fg = '#ffaf5f', bg = '#585858', bold = true })

-- 模式指示器
c(0, 'ModeNormal', { fg = '#ffffff', bg = '#585858', bold = true })
c(0, 'ModeInsert', { fg = '#5fafff', bg = '#585858', bold = true })
c(0, 'ModeVisual', { fg = '#87d787', bg = '#585858', bold = true })
c(0, 'ModeVLine', { fg = '#5faf5f', bg = '#585858', bold = true })
c(0, 'ModeVBlock', { fg = '#5fd7ff', bg = '#585858', bold = true })
c(0, 'ModeReplace', { fg = '#d787ff', bg = '#585858', bold = true })
c(0, 'ModeCmdline', { fg = '#ff5f5f', bg = '#585858', bold = true })
c(0, 'ModeTerminal', { fg = '#ffd700', bg = '#585858', bold = true })

-- 标签栏
c(0, 'TabLine', { fg = '#a8a8a8', bg = '#3a3a3a' })
c(0, 'TabLineSel', { fg = '#ffd700', bg = '#262626', bold = true })
c(0, 'TabLineFill', { bg = '#3a3a3a' })

-- 终端配色
-- Neovim 内部终端的 ANSI 16 色（Nord 调色板）
local term_colors = {
    -- 0-7 普通色
    '#2a2a2a', '#c06c75', '#98c379', '#d6b370',
    '#61afef', '#c678dd', '#56b6c2', '#c8c8c8',
    -- 8-15 亮色
    '#5c6370', '#c06c75', '#98c379', '#d6b370',
    '#61afef', '#c678dd', '#56b6c2', '#ffffff',
}
for i = 0, 15 do
    vim.g['terminal_color_' .. i] = term_colors[i + 1]
end

-- 15. 边界线
opt.colorcolumn = '120'
c(0, 'ColorColumn', { bg = '#1a1a1a' })

return M
