-- ============================================================
-- 界面显示：行号、光标、边界线
-- ============================================================
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.showmode = false
opt.laststatus = 2
opt.ruler = true
opt.title = true

-- 进入插入模式用绝对行号，退出恢复相对行号
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
    callback = function() vim.opt.relativenumber = true end,
})

-- 边界线
opt.colorcolumn = '120'

-- 行尾空格显示成一个淡灰的 ·，不用背景块也不用下划线。
-- tab / 行尾 / 折行标记设成空格，等于关掉，避免满屏 ^I 和 $。
opt.list = true
opt.listchars = { trail = '·', tab = '  ', eol = ' ', extends = ' ', precedes = ' ', nbsp = ' ' }

-- 光标形状与闪烁：普通/可视 = 方块，插入 = 竖线，替换 = 下划线
opt.guicursor = {
    'n-v-c-sm:block-Cursor-blinkwait1000-blinkon500-blinkoff500',
    'i-ci-ve:ver25-Cursor-blinkwait1000-blinkon500-blinkoff500',
    'r-cr-o:hor20-Cursor-blinkwait1000-blinkon500-blinkoff500',
}

return {}
