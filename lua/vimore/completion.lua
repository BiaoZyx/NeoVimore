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
    '*.pyc',
    '*.pyo',
    '*.swp',
    '*.swo',
    '*.so',
    '*.dll',
    '*.exe',
    '*.jpg',
    '*.png',
    '*.gif',
    '*.bmp',
    '*.ico',
    '*.zip',
    '*.tar',
    '*.gz',
    '*.bz2',
    'node_modules',
    '__pycache__',
    '*.git',
    '*.svn',
    '*.o',
    '*.a',
    '*.obj',
    '*.class',
}

-- 弹出菜单中 TAB / S-TAB 选择
vim.keymap.set(
    'i',
    '<Tab>',
    function() return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>' end,
    { expr = true, silent = true, desc = 'Next completion item' }
)
vim.keymap.set(
    'i',
    '<S-Tab>',
    function() return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>' end,
    { expr = true, silent = true, desc = 'Previous completion item' }
)

-- <CR> 智能拆分：菜单可见时确认选择，紧挨 () {} [] 时拆成三行
vim.keymap.set('i', '<CR>', function()
    if vim.fn.pumvisible() == 1 then return '<C-y>' end
    return M.smart_enter()
end, { expr = true, silent = true, desc = 'Enter / confirm completion / split pair' })

local pairs_map = { ['{'] = '}', ['('] = ')', ['['] = ']' }

local function indent_step()
    local sw = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop
    return vim.bo.expandtab and string.rep(' ', sw) or '\t'
end

-- 光标停在一对空括号中间：{} / () / []
local function between_pair(line, col)
    local before = line:sub(col, col)
    local after = line:sub(col + 1, col + 1)
    return pairs_map[before] ~= nil and after == pairs_map[before]
end

-- 光标停在容器右括号上，且左边有配套的同类左括号和内容：
--   local xs = [1, 2, 3|]
-- 返回左括号的 1-based 位置和中间内容。
local function container_at_end(line, col)
    local close_pos = col + 1
    local close = line:sub(close_pos, close_pos)
    if close == '' then return nil end

    local open_char
    for o, c in pairs(pairs_map) do
        if c == close then
            open_char = o
            break
        end
    end
    if not open_char then return nil end

    local depth, open_pos = 1, nil
    for i = close_pos - 1, 1, -1 do
        local ch = line:sub(i, i)
        if ch == close then
            depth = depth + 1
        elseif ch == open_char then
            depth = depth - 1
            if depth == 0 then
                open_pos = i
                break
            end
        end
    end
    if not open_pos or open_pos >= close_pos then return nil end

    local inner = line:sub(open_pos + 1, close_pos - 1)
    if not inner:match('%S') then return nil end
    -- 右括号后面只能有空白，确保是在「容器末尾」回车
    if not line:sub(close_pos + 1):match('^%s*$') then return nil end
    return open_pos, inner
end

-- 注意：expr 映射求值期间有 textlock，不能直接改 buffer。
-- 因此这里只安排一个 scheduled 编辑，并返回 <Ignore> 保持 insert 模式。
-- 旧的 <C-o> 会短暂进入 normal，LSP 的诊断标签会闪一下。
function M.smart_enter()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    if between_pair(line, col) then
        vim.schedule(M.split_pair)
        return '<Ignore>'
    end

    if container_at_end(line, col) then
        vim.schedule(M.split_container_end)
        return '<Ignore>'
    end

    return '<CR>'
end

-- 在 () {} [] 中间回车：拆成三行并把光标放中间
function M.split_pair()
    local lnum = vim.fn.line('.')
    local line = vim.fn.getline(lnum)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local indent = line:match('^%s*')
    -- 尊重 noexpandtab：用 tab 的文件补一个制表符，而不是硬塞空格
    local inner = indent .. indent_step()

    local line1 = line:sub(1, col)
    local line2 = inner
    local line3 = indent .. line:sub(col + 1)

    vim.fn.setline(lnum, line1)
    vim.fn.append(lnum, line2)
    vim.fn.append(lnum + 1, line3)

    vim.api.nvim_win_set_cursor(0, { lnum + 1, #line2 })
end

-- 在数组 / 对象等包裹容器末尾回车：把右括号挪到下一行，
-- 内容单独占一行，光标停在那一行末尾。
function M.split_container_end()
    local lnum = vim.fn.line('.')
    local line = vim.fn.getline(lnum)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local open_pos, inner = container_at_end(line, col)
    if not open_pos then return false end

    local indent = line:match('^%s*') or ''
    local middle = indent .. indent_step() .. inner:match('^%s*(.-)%s*$')
    local last = indent .. line:sub(col + 1)

    vim.fn.setline(lnum, line:sub(1, open_pos))
    vim.fn.append(lnum, middle)
    vim.fn.append(lnum + 1, last)
    vim.api.nvim_win_set_cursor(0, { lnum + 1, #middle })
    return true
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
    perl = 'perlcomplete#Complete',
    xml = 'xmlcomplete#CompleteTags',
}

local function set_omnifunc()
    local ft = vim.bo.filetype
    -- LSP 已附加时不覆盖
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then return end
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
