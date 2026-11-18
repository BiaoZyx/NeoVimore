-- ============================================================
-- 基础选项：编码、缩进、搜索、编辑行为
-- ============================================================
local M = {}

local opt = vim.opt

-- ---------- 基础 ----------
vim.g.mapleader = ' ' -- Leader 键设为空格
opt.background = 'dark'

-- 只在确实支持真彩色的终端里开启 termguicolors；否则用配色自带的
-- 256 色回退，避免 hex 颜色在不兼容终端上显示成奇怪的灰块。
local term = vim.env.TERM or ''
local colorterm = vim.env.COLORTERM or ''
local truecolor = colorterm:find('truecolor', 1, true) ~= nil
    or colorterm:find('24bit', 1, true) ~= nil
    or term:find('truecolor', 1, true) ~= nil
    or term:find('direct', 1, true) ~= nil
    or vim.g.neovide == true
if vim.fn.has('termguicolors') == 1 and (vim.fn.has('gui_running') == 1 or truecolor) then
    opt.termguicolors = true
else
    opt.termguicolors = false
end

opt.clipboard = '' -- 不自动同步系统剪切板，用菜单里的 SPC y / p / P 手动控制

-- 在 Neovim 默认值上追加，不覆盖 F/o/O/C/l 等已有短消息规则
opt.shortmess:append('tT')

-- 插入模式补全菜单高度 / 诊断刷新速度
opt.pumheight = 15
opt.updatetime = 250
-- Neovim 的 signcolumn=yes 默认占 2 列，看起来像凭空多了两列空白。
-- 用 auto:1：平时不占位，真有诊断符号时才占 1 列。
opt.signcolumn = 'auto:1'

-- 分屏默认往右、往下开
opt.splitright = true
opt.splitbelow = true

-- Neovim 0.11+ 的浮动窗口默认边框
if vim.fn.exists('+winborder') == 1 then opt.winborder = 'rounded' end

-- ---------- 编码与文件 ----------
opt.fileencoding = 'utf-8'
opt.fileencodings = { 'utf-8', 'gbk', 'cp936', 'gb2312', 'gb18030', 'ucs-bom' }
opt.fileformats = { 'unix', 'dos', 'mac' }

-- 备份、交换、撤销文件：统一放 Neovim state 目录
local state_dir = vim.fn.stdpath('state')
for _, dir in ipairs({ 'undo', 'backup', 'swap' }) do
    local path = state_dir .. '/' .. dir
    if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p') end
end

opt.backup = true
opt.swapfile = true
opt.writebackup = true
opt.undofile = true
opt.undodir = state_dir .. '/undo'
opt.backupdir = state_dir .. '/backup'
opt.directory = state_dir .. '/swap'

opt.autoread = true
opt.confirm = true
opt.hidden = true
opt.history = 2000
opt.undolevels = 1000

-- ---------- 缩进与格式 ----------
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smarttab = true
opt.autoindent = true
opt.shiftround = true
opt.infercase = true

-- 具体文件类型的缩进交给 ftplugin；这里只补两条通用规则：
-- m: 允许在中文等多字节字符处断行；B: 连接行时不插入注释符
opt.formatoptions:append('mB')
opt.linebreak = true
opt.textwidth = 0
opt.wrap = false
opt.showbreak = ''

-- ---------- 搜索与替换 ----------
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.wrapscan = true
opt.gdefault = true

-- ---------- 编辑行为 ----------
opt.backspace = { 'indent', 'eol', 'start' }
opt.scrolloff = 5
opt.sidescrolloff = 8
opt.sidescroll = 10
opt.virtualedit = 'block'
opt.selection = 'inclusive'
opt.mouse = 'a'
opt.mousemodel = 'popup'
opt.keymodel = { 'startsel', 'stopsel' }

opt.timeoutlen = 300
opt.ttimeoutlen = 50

-- 保存并稍后清除提示信息（被 <C-s> 和菜单共用）
function M.save_and_clear()
    if vim.bo.buftype ~= '' or vim.fn.expand('%') == '' then
        vim.api.nvim_echo({ { '当前 buffer 没有文件名，无法保存', 'WarningMsg' } }, false, {})
        return
    end

    local ok, err = pcall(vim.cmd.write)
    if not ok then
        vim.api.nvim_echo({ { '保存失败: ' .. tostring(err), 'ErrorMsg' } }, false, {})
        return
    end

    vim.api.nvim_echo({ { '已保存', 'ModeMsg' } }, false, {})
    vim.fn.timer_start(2000, function() vim.cmd('echo ""') end)
end

-- 粘贴模式开关（原版 pastetoggle 已被 Neovim 移除）
vim.keymap.set({ 'n', 'i' }, '<F2>', function()
    vim.opt.paste = not vim.opt.paste:get()
    if vim.opt.paste:get() then
        vim.api.nvim_echo({ { '粘贴模式: 开', 'WarningMsg' } }, false, {})
    else
        vim.api.nvim_echo({ { '粘贴模式: 关', 'ModeMsg' } }, false, {})
    end
end, { desc = '切换粘贴模式' })

return M
