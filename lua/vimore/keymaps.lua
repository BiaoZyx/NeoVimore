-- ============================================================
-- 快捷键：保存、窗口、标签页、F 键
-- Leader 下的命令统一收在 menu.lua，这里不重复定义
-- ============================================================
local map = vim.keymap.set

-- ---------- 保存 ----------
map('n', '<C-s>', function() require('vimore.options').save_and_clear() end, { desc = 'Save' })
map('i', '<C-s>', '<Cmd>lua require("vimore.options").save_and_clear()<CR>', { desc = 'Save' })

-- ---------- 窗口切换 ----------
map('n', '<C-h>', '<C-w>h', { desc = 'Go to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to right window' })

-- ---------- 标签页切换 ----------
map('n', '<A-Left>', '<Cmd>tabprevious<CR>', { silent = true, desc = 'Previous tab' })
map('n', '<A-Right>', '<Cmd>tabnext<CR>', { silent = true, desc = 'Next tab' })

-- ---------- 可视模式剪切 ----------
map('x', '<C-x>', '"+x', { desc = 'Cut to system clipboard' })

-- 可视模式缩进后保持选中，方便连续缩进
map('x', '<', '<gv', { silent = true, desc = 'Outdent selection' })
map('x', '>', '>gv', { silent = true, desc = 'Indent selection' })

-- ---------- F 键 ----------
-- F1 帮助（保留默认） / F2 粘贴模式（见 options.lua）
map('n', '<F3>', '<Cmd>Explore<CR>', { silent = true, desc = 'File explorer' })
map('n', '<F4>', '<Cmd>Vexplore<CR>', { silent = true, desc = 'Vertical file explorer' })
map('n', '<F5>', function() require('vimore.terminal').run_in_latest() end, { desc = 'Run code' })
map('n', '<F6>', function() require('vimore.runner').debug() end, { desc = 'Debug code' })
map('n', '<F7>', function()
    vim.b.vimore_wrap_override = true
    local wrap = not vim.opt_local.wrap:get()
    vim.opt_local.wrap = wrap
    vim.opt_local.linebreak = wrap
    -- showbreak 只在折行时才有意义
    vim.opt_local.showbreak = wrap and '↪' or ''
    vim.api.nvim_echo({ { 'wrap = ' .. tostring(wrap), 'ModeMsg' } }, false, {})
end, { desc = 'Toggle line wrap' })
map('n', '<F8>', function() require('vimore.runner').check() end, { desc = 'Check code' })
map('n', '<F9>', 'gg=G', { silent = true, desc = 'Basic indent (gg=G)' })
map('n', '<F10>', function() require('vimore.runner').format() end, { desc = 'Auto format' })

return {}
