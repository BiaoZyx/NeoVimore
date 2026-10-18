-- ============================================================
-- 1. 基础设置 / 4. 编码与文件 / 5. 缩进与格式
-- 6. 搜索与替换 / 7. 编辑行为
-- ============================================================
local M = {}

local opt = vim.opt

-- ---------- 1. 基础设置 ----------
vim.g.mapleader = ' ' -- Leader 键设为空格
opt.clipboard = '' -- 不自动同步系统剪切板，用 Ctrl+C/V 手动控制
opt.background = 'dark'

-- 启动信息精简：a=缩写, o=覆盖写入, O=覆盖读取, t=启动提示, T=标签页信息
opt.shortmess = 'aoOtT'

-- Neovim 默认已开启 filetype 检测/缩进/插件，显式声明保持原版语义
vim.cmd('filetype plugin indent on')

-- 插入模式补全弹出菜单垂直长度
opt.pumheight = 15

-- ---------- 4. 编码与文件 ----------
-- Neovim 内部固定 utf-8，保留 fileencodings 兼容旧文件
opt.fileencoding = 'utf-8'
opt.fileencodings = { 'utf-8', 'gbk', 'cp936', 'gb2312', 'gb18030', 'ucs-bom' }
opt.fileformats = { 'unix', 'dos', 'mac' }

-- 备份、交换、撤销文件：统一放 Neovim state 目录
local state_dir = vim.fn.stdpath('state')
for _, dir in ipairs({ 'undo', 'backup', 'swap' }) do
    local path = state_dir .. '/' .. dir
    if vim.fn.isdirectory(path) == 0 then
        vim.fn.mkdir(path, 'p')
    end
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

-- ---------- 5. 缩进与格式 ----------
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smarttab = true
opt.autoindent = true
opt.cindent = true
opt.shiftround = true
opt.infercase = true
vim.cmd('set formatoptions+=mB')
opt.linebreak = true
opt.textwidth = 0 -- 禁止自动换行
opt.wrap = false
opt.showbreak = ''

-- 限制语法同步范围（避免每次重绘都从头解析整个文件）
vim.cmd('syntax sync minlines=200')
vim.cmd('syntax sync maxlines=500')

-- 各文件类型自定义缩进
local indent_group = vim.api.nvim_create_augroup('VimoreIndent', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = indent_group,
    pattern = { 'python', 'sh' },
    callback = function() vim.bo.tabstop = 4 vim.bo.shiftwidth = 4 vim.bo.softtabstop = 4 vim.bo.expandtab = true end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = indent_group,
    pattern = 'go',
    callback = function() vim.bo.tabstop = 4 vim.bo.shiftwidth = 4 vim.bo.softtabstop = 4 vim.bo.expandtab = false end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = indent_group,
    pattern = { 'javascript', 'typescript', 'html', 'css', 'json', 'yaml', 'markdown' },
    callback = function() vim.bo.tabstop = 2 vim.bo.shiftwidth = 2 vim.bo.softtabstop = 2 vim.bo.expandtab = true end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = indent_group,
    pattern = { 'c', 'cpp', 'java', 'rust' },
    callback = function() vim.bo.tabstop = 4 vim.bo.shiftwidth = 4 vim.bo.softtabstop = 4 vim.bo.expandtab = true end,
})

-- ---------- 6. 搜索与替换 ----------
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.wrapscan = true
opt.gdefault = true

-- ---------- 7. 编辑行为 ----------
opt.backspace = { 'indent', 'eol', 'start' }
vim.cmd('set whichwrap+=<,>,h,l,b,s')
opt.scrolloff = 5
opt.sidescrolloff = 8
opt.sidescroll = 10
opt.virtualedit = 'block'
opt.selection = 'inclusive'
opt.mouse = 'a'
opt.mousemodel = 'popup'
opt.keymodel = { 'startsel', 'stopsel' }

-- 缩短普通映射超时 / 按键码超时
opt.timeoutlen = 300
opt.ttimeoutlen = 50

-- 光标形状（替代原版 t_SI/t_EI 转义序列）：
-- 普通/可视 = 方块，插入 = 竖线，替换 = 下划线
opt.guicursor = {
    'n-v-c-sm:block-Cursor',
    'i-ci-ve:ver25-Cursor',
    'r-cr-o:hor20-Cursor',
}

-- 使用 j, k 默认切换屏幕行（带计数时走物理行）
vim.keymap.set('n', 'j', function()
    return vim.v.count ~= 0 and 'j' or 'gj'
end, { expr = true, silent = true, desc = '屏幕行向下' })
vim.keymap.set('n', 'k', function()
    return vim.v.count ~= 0 and 'k' or 'gk'
end, { expr = true, silent = true, desc = '屏幕行向上' })

-- 保存并稍后清除提示信息
function M.save_and_clear()
    vim.cmd.write()
    vim.fn.timer_start(2000, function()
        vim.cmd('echo ""')
    end)
end

-- 粘贴模式开关（原版 pastetoggle 已被 Neovim 移除，改用映射）
vim.keymap.set({ 'n', 'i' }, '<F2>', function()
    vim.opt.paste = not vim.opt.paste:get()
    if vim.opt.paste:get() then
        vim.api.nvim_echo({ { '粘贴模式: 开', 'WarningMsg' } }, false, {})
    else
        vim.api.nvim_echo({ { '粘贴模式: 关', 'ModeMsg' } }, false, {})
    end
end, { desc = '切换粘贴模式' })

return M
