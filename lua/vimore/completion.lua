-- ============================================================
-- 12. 补全
-- ============================================================
local M = {}

local opt = vim.opt

opt.completeopt = { 'menuone', 'noinsert', 'noselect', 'preview' }
opt.complete = { '.', 'w', 'b', 'u', 't', 'i', 'k' }
opt.wildmenu = true
opt.wildmode = { 'full' }
opt.wildignorecase = true
opt.wildignore = {
    '*.pyc', '*.pyo', '*.swp', '*.swo', '*.so', '*.dll', '*.exe',
    '*.jpg', '*.png', '*.gif', '*.bmp', '*.ico',
    '*.zip', '*.tar', '*.gz', '*.bz2',
    'node_modules', '__pycache__', '*.git', '*.svn',
    '*.o', '*.a', '*.obj', '*.class',
}

-- 弹出菜单中 TAB / S-TAB 选择
vim.keymap.set('i', '<Tab>', function()
    return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
end, { expr = true, silent = true, desc = '补全菜单下一项' })
vim.keymap.set('i', '<S-Tab>', function()
    return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
end, { expr = true, silent = true, desc = '补全菜单上一项' })

-- <CR> 智能拆分：菜单可见时确认选择，紧挨 () {} [] 时拆成三行
vim.keymap.set('i', '<CR>', function()
    if vim.fn.pumvisible() == 1 then
        return '<C-y>'
    end
    return M.smart_enter()
end, { expr = true, silent = true, desc = '回车 / 确认补全 / 拆分括号' })

function M.smart_enter()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    if col > 0 and col < #line then
        local before = line:sub(col, col)
        local after = line:sub(col + 1, col + 1)
        local pairs_map = { ['{'] = '}', ['('] = ')', ['['] = ']' }
        if pairs_map[before] and after == pairs_map[before] then
            return '<C-o>:call v:lua.require("vimore.completion").split_pair()<CR>'
        end
    end

    return '<CR>'
end

-- 在 () {} [] 中间回车：拆成三行并把光标放中间
function M.split_pair()
    local lnum = vim.fn.line('.')
    local line = vim.fn.getline(lnum)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local indent = line:match('^%s*')
    local inner = indent .. string.rep(' ', vim.bo.shiftwidth)

    local line1 = line:sub(1, col)
    local line2 = inner
    local line3 = indent .. line:sub(col + 1)

    vim.fn.setline(lnum, line1)
    vim.fn.append(lnum, line2)
    vim.fn.append(lnum + 1, line3)

    vim.api.nvim_win_set_cursor(0, { lnum + 1, #line2 })
end

-- 各语言补全函数（LSP 接管后由 lsp.lua 覆盖为 vim.lsp.omnifunc）
local omni_func_map = {
    python = 'python3complete#Complete',
    javascript = 'javascriptcomplete#CompleteJS',
    html = 'htmlcomplete#CompleteTags',
    css = 'csscomplete#CompleteCSS',
    c = 'ccomplete#Complete',
    cpp = 'cppcomplete#Complete',
    go = 'go#complete#Complete',
    ruby = 'rubycomplete#Complete',
    php = 'phpcomplete#Complete',
    xml = 'xmlcomplete#CompleteTags',
}

local function set_omnifunc()
    local ft = vim.bo.filetype
    -- LSP 已附加时不覆盖
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
        return
    end
    if omni_func_map[ft] then
        vim.bo.omnifunc = omni_func_map[ft]
    else
        vim.bo.omnifunc = 'syntaxcomplete#Complete'
    end
end

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('VimoreOmni', { clear = true }),
    callback = set_omnifunc,
})

return M
