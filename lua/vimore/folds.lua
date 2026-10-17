-- ============================================================
-- 13. 代码折叠
-- ============================================================
local M = {}

function M.foldtext()
    local line = vim.fn.getline(vim.v.foldstart)
    local n = vim.v.foldend - vim.v.foldstart + 1
    return '+ ' .. line .. ' ... ' .. n .. ' lines'
end

vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 99
vim.opt.foldenable = true
vim.opt.foldnestmax = 5
vim.opt.foldminlines = 2
vim.opt.foldtext = "v:lua.require('vimore.folds').foldtext()"

return M
