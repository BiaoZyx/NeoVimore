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

-- 手动切换当前 buffer 的 Treesitter / 正则语法高亮。
-- 遇到不兼容的旧 queries 时（比如某些 sh 文件），按 SPC c s 关掉即可。
function M.toggle(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    if vim.treesitter.highlighter.active[bufnr] then
        pcall(vim.treesitter.stop, bufnr)
        vim.b[bufnr].vimore_ts_checked = true
        vim.notify('vimore: Treesitter off (regex syntax)', vim.log.levels.INFO)
        return
    end

    local ft = vim.bo[bufnr].filetype
    if ft == '' then
        vim.notify('vimore: current buffer has no filetype', vim.log.levels.WARN)
        return
    end
    local lang = vim.treesitter.language.get_lang(ft) or ft
    local ok = pcall(vim.treesitter.language.add, lang)
    if not ok then
        vim.notify('vimore: no parser for ' .. ft, vim.log.levels.WARN)
        return
    end
    vim.b[bufnr].vimore_ts_checked = true
    pcall(vim.treesitter.start, bufnr, lang)
    vim.notify('vimore: Treesitter on (' .. lang .. ')', vim.log.levels.INFO)
end

function M.attach()
    local group = api.nvim_create_augroup('VimoreTreesitter', { clear = true })
    api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(args) start(args.buf) end,
    })
end

return M
