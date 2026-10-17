-- ============================================================
-- 9. 复制粘贴 / 16. 普通快捷键 / 17. F 键快捷键 / 可视模式缩进
-- ============================================================
local M = {}

local map = vim.keymap.set

-- ---------- 9. 复制粘贴（手动切换内置/系统寄存器） ----------
map('n', '<Leader>y', '"+yy', { desc = '复制行到系统剪切板' })
map('x', '<Leader>y', '"+y', { desc = '复制选区到系统剪切板' })
map('n', '<Leader>p', '"+p', { desc = '从系统剪切板粘贴' })
map('n', '<Leader>P', '"+P', { desc = '从系统剪切板前插粘贴' })
map('x', '<Leader>p', '"+p', { desc = '从系统剪切板粘贴' })
map('x', '<Leader>P', '"+P', { desc = '从系统剪切板前插粘贴' })

-- ---------- 16. 普通快捷键（无 leader） ----------
-- 保存
map('n', '<C-s>', function() require('vimore.options').save_and_clear() end, { desc = '保存' })
map('i', '<C-s>', '<Esc>:call v:lua.require("vimore.options").save_and_clear()<CR>', { desc = '保存' })

-- 窗口切换
map('n', '<C-h>', '<C-w>h', { desc = '切到左窗口' })
map('n', '<C-j>', '<C-w>j', { desc = '切到下窗口' })
map('n', '<C-k>', '<C-w>k', { desc = '切到上窗口' })
map('n', '<C-l>', '<C-w>l', { desc = '切到右窗口' })

-- 标签页切换
map('n', '<A-Left>', ':tabp<CR>', { silent = true, desc = '上一个标签' })
map('n', '<A-Right>', ':tabn<CR>', { silent = true, desc = '下一个标签' })
map('n', '<C-t>', ':tabnew<CR>', { silent = true, desc = '新建标签' })

-- 可视模式剪切
map('x', '<C-x>', '"+x', { desc = '剪切到系统剪切板' })

-- 普通模式：单按 < / > 缩进当前行
map('n', '<', ':<C-u>silent! normal! <<<CR>', { silent = true, desc = '缩进当前行' })
map('n', '>', ':<C-u>silent! normal! >><CR>', { silent = true, desc = '反缩进当前行' })

-- 可视模式：缩进选区并保持选中（方便连续缩进）
map('x', '<', '<gv', { silent = true, desc = '缩进选区' })
map('x', '>', '>gv', { silent = true, desc = '反缩进选区' })

-- ---------- 17. F 键快捷键 ----------
-- F1 - 帮助（保留默认）
-- F2 - 粘贴模式总开关（见 options.lua）
map('n', '<F3>', ':Explore<CR>', { silent = true, desc = '文件浏览器' })
map('n', '<F4>', ':Vexplore<CR>', { silent = true, desc = '垂直文件浏览器' })
map('n', '<F5>', function() require('vimore.terminal').run_in_latest() end, { desc = '运行代码' })
map('n', '<F6>', function() require('vimore.runner').debug() end, { desc = '调试代码' })
map('n', '<F7>', function()
    vim.opt.wrap = not vim.opt.wrap:get()
    vim.api.nvim_echo({ { 'wrap = ' .. tostring(vim.opt.wrap:get()) } }, false, {})
end, { desc = '切换自动换行' })
map('n', '<F8>', function() require('vimore.runner').check() end, { desc = '代码检查' })
map('n', '<F9>', 'gg=G', { silent = true, desc = '基础格式化' })
map('n', '<F10>', function() require('vimore.runner').format() end, { desc = '自动格式化' })

return M
