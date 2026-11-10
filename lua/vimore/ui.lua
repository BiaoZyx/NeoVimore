-- ============================================================
-- 2. 界面显示 / 15. 边界线
-- ============================================================
local M = {}

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
    callback = function()
        vim.opt.relativenumber = true
    end,
})

-- 边界线
opt.colorcolumn = '120'

-- 光标闪烁
opt.guicursor = {
    'n-v-c-sm:block-Cursor-blinkwait1000-blinkon600-blinkoff600',
    'i-ci-ve:ver25-Cursor-blinkwait1000-blinkon600-blinkoff600',
    'r-cr-o:hor20-Cursor-blinkwait1000-blinkon600-blinkoff600',
}

return M
