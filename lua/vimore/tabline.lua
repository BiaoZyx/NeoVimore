-- ============================================================
-- 22. 标签栏
-- ============================================================
local M = {}

local function truncate(str, cells)
    if cells < 1 then
        return ''
    end
    if vim.fn.strdisplaywidth(str) <= cells then
        return str
    end
    local n = vim.fn.strchars(str)
    local out = ''
    for i = 1, n do
        local cand = out .. vim.fn.strcharpart(str, i - 1, 1)
        if vim.fn.strdisplaywidth(cand) > cells - 1 then
            break
        end
        out = cand
    end
    return out .. '…'
end

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
        bufname = truncate(bufname, name_len)

        local modified = vim.bo[buflist[winnr]].modified and '+' or ''
        local label = ' ' .. i .. ':' .. bufname .. modified
        label = label .. string.rep(' ', math.max(0, width - vim.fn.strdisplaywidth(label)))

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
