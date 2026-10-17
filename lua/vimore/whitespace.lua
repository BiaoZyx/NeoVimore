-- ============================================================
-- 14. 行尾空格显示与清理
-- ============================================================
local M = {}

vim.api.nvim_set_hl(0, 'ExtraWhitespace', { fg = '#666666' })
vim.fn.match('ExtraWhitespace', [[\s\+$]])

function M.strip()
    local pos = vim.fn.getpos('.')
    pcall(vim.cmd, [[%s/\s\+$//e]])
    vim.fn.setpos('.', pos)
end

-- 保存时自动清理行尾空格（Markdown 除外）
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('VimoreWhitespace', { clear = true }),
    callback = function()
        if vim.bo.filetype == 'markdown' then
            return
        end
        M.strip()
    end,
})

-- 手动清理（Leader 菜单入口）
function M.strip_manual()
    M.strip()
    vim.api.nvim_echo({ { '已清理行尾空格', 'ModeMsg' } }, false, {})
    vim.fn.timer_start(2000, function()
        vim.cmd('echo ""')
    end)
end

return M
