-- ============================================================
-- Treesitter 高亮：按 FileType 自动启动（LazyVim 式做法）
-- 颜色交给 colors/vimore.lua 的 @group；这里只负责启动。
-- 没装 parser 的文件类型自动跳过，退回 Vim 正则语法高亮。
-- ============================================================
local M = {}

local api = vim.api

local function start(buf)
    if vim.g.vimore_auto_treesitter == false then return end
    if vim.b[buf].vimore_ts_checked then return end
    vim.b[buf].vimore_ts_checked = true

    local ft = vim.bo[buf].filetype
    if ft == '' then return end
    local lang = vim.treesitter.language.get_lang(ft) or ft
    local ok = pcall(vim.treesitter.language.add, lang)
    if not ok then return end
    pcall(vim.treesitter.start, buf, lang)
end

function M.attach()
    local group = api.nvim_create_augroup('VimoreTreesitter', { clear = true })
    api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(args) start(args.buf) end,
    })
end

return M
