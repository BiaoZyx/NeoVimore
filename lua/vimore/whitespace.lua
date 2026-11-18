-- ============================================================
-- 行尾空格显示与清理
-- ============================================================
local M = {}

-- 行尾空格靠 listchars 的 · 显示，只在可编辑的普通文件里开 list；
-- 终端 / 帮助 / nofile 缓冲不显示，更不会有任何背景块。
local function ensure_list()
    local enabled = vim.g.vimore_show_extra_whitespace ~= false and vim.bo.buftype == '' and vim.bo.modifiable
    vim.opt_local.list = enabled
end

ensure_list()
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'TermOpen' }, {
    group = vim.api.nvim_create_augroup('VimoreWhitespaceHL', { clear = true }),
    callback = ensure_list,
})

function M.strip()
    local pos = vim.fn.getpos('.')
    pcall(vim.cmd, [[%s/\s\+$//e]])
    vim.fn.setpos('.', pos)
end

local skip_fts = {
    markdown = true, -- 行尾两个空格是硬换行
    diff = true,
    gitcommit = true,
}

local function should_strip()
    if vim.g.vimore_strip_whitespace == false then return false end
    if vim.bo.buftype ~= '' or not vim.bo.modifiable then return false end
    return not skip_fts[vim.bo.filetype]
end

-- 保存时自动清理行尾空格
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('VimoreWhitespace', { clear = true }),
    callback = function()
        if should_strip() then M.strip() end
    end,
})

-- 手动清理（Leader 菜单入口）
function M.strip_manual()
    M.strip()
    vim.api.nvim_echo({ { '已清理行尾空格', 'ModeMsg' } }, false, {})
    vim.fn.timer_start(2000, function() vim.cmd('echo ""') end)
end

return M
