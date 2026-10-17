-- ============================================================
-- 22. 标签栏
-- ============================================================
local M = {}

function M.render()
    local s = ''
    local cur = vim.fn.tabpagenr()
    local total = vim.fn.tabpagenr('$')

    local width = math.floor((vim.o.columns - 2) / total)
    if width < 8 then width = 8 end
    local padding = 2

    for i = 1, total do
        local buflist = vim.fn.tabpagebuflist(i)
        local winnr = vim.fn.tabpagewinnr(i)
        local bufname = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ':t')
        if bufname == '' then bufname = '[No Name]' end

        local name_len = width - #(i .. ':') - 2 - padding
        if #bufname > name_len then
            bufname = bufname:sub(1, name_len - 2) .. '…'
        end

        local modified = vim.bo[buflist[winnr]].modified and '+' or ''
        local label = ' ' .. i .. ':' .. bufname .. modified
        label = label .. string.rep(' ', math.max(0, width - #label))

        if i == cur then
            s = s .. '%#TabLineSel#' .. label
        else
            s = s .. '%#TabLine#' .. label
        end
    end

    s = s .. '%#TabLineFill#%T'
    return s
end

vim.o.showtabline = 1
vim.o.tabline = '%!v:lua.require("vimore.tabline").render()'

return M
