-- ============================================================
-- 快捷键：保存、窗口、标签页、F 键
-- Leader 下的命令统一收在 menu.lua，这里不重复定义
-- ============================================================
local map = vim.keymap.set

-- ---------- 保存 ----------
map('n', '<C-s>', function() require('vimore.options').save_and_clear() end, { desc = '保存' })
map('i', '<C-s>', '<Cmd>lua require("vimore.options").save_and_clear()<CR>', { desc = '保存' })

-- ---------- 窗口切换 ----------
map('n', '<C-h>', '<C-w>h', { desc = '切到左窗口' })
map('n', '<C-j>', '<C-w>j', { desc = '切到下窗口' })
map('n', '<C-k>', '<C-w>k', { desc = '切到上窗口' })
map('n', '<C-l>', '<C-w>l', { desc = '切到右窗口' })

-- ---------- 标签页切换 ----------
map('n', '<A-Left>', '<Cmd>tabprevious<CR>', { silent = true, desc = '上一个标签' })
map('n', '<A-Right>', '<Cmd>tabnext<CR>', { silent = true, desc = '下一个标签' })

-- ---------- 可视模式剪切 ----------
map('x', '<C-x>', '"+x', { desc = '剪切到系统剪切板' })

-- 可视模式缩进后保持选中，方便连续缩进
map('x', '<', '<gv', { silent = true, desc = '反缩进选区' })
map('x', '>', '>gv', { silent = true, desc = '缩进选区' })

-- ---------- F 键 ----------
-- F1 帮助（保留默认） / F2 粘贴模式（见 options.lua）
map('n', '<F3>', '<Cmd>Explore<CR>', { silent = true, desc = '文件浏览器' })
map('n', '<F4>', '<Cmd>Vexplore<CR>', { silent = true, desc = '垂直文件浏览器' })
map('n', '<F5>', function() require('vimore.terminal').run_in_latest() end, { desc = '运行代码' })
map('n', '<F6>', function() require('vimore.runner').debug() end, { desc = '调试代码' })
map('n', '<F7>', function()
    vim.b.vimore_wrap_override = true
    local wrap = not vim.opt_local.wrap:get()
    vim.opt_local.wrap = wrap
    vim.opt_local.linebreak = wrap
    -- showbreak 只在折行时才有意义
    vim.opt_local.showbreak = wrap and '↪' or ''
    vim.api.nvim_echo({ { 'wrap = ' .. tostring(wrap), 'ModeMsg' } }, false, {})
end, { desc = '切换自动换行' })
map('n', '<F8>', function() require('vimore.runner').check() end, { desc = '代码检查' })
map('n', '<F9>', 'gg=G', { silent = true, desc = '基础格式化' })
map('n', '<F10>', function() require('vimore.runner').format() end, { desc = '自动格式化' })

return {}
