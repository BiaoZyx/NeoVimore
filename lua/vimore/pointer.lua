-- ============================================================
-- 跨语言语义着色补丁
-- 不依赖 treesitter highlighter / LSP semantic tokens，直接用
-- treesitter parser 给运算符和 C/C++ 指针 * 打 extmark。
-- 这样各语言的 = + > 等颜色一致，指针 * 仍是蓝色。
-- ============================================================
local M = {}

local api = vim.api
local ns_pointer = api.nvim_create_namespace('vimore.pointer')
local ns_operator = api.nvim_create_namespace('vimore.operator')

local pointer_queries = {}
local operator_queries = {}

local operator_tokens = {
    '=',
    '+',
    '-',
    '*',
    '/',
    '%',
    '>',
    '<',
    '>=',
    '<=',
    '==',
    '!=',
    '&&',
    '||',
    '!',
    '+=',
    '-=',
    '*=',
    '/=',
}

local no_operator_ft = {
    yaml = true,
    json = true,
    jsonc = true,
    markdown = true,
    toml = true,
    text = true,
    help = true,
    vim = true,
}

local function get_pointer_query(ft)
    if pointer_queries[ft] ~= nil then return pointer_queries[ft] end
    local ok, query = pcall(
        vim.treesitter.query.parse,
        ft,
        [[
        (pointer_declarator "*" @vimore.pointer)
        (pointer_expression "*" @vimore.pointer)
    ]]
    )
    if not ok then query = false end
    pointer_queries[ft] = query
    return query
end

-- 逐 token 试探该 grammar 是否认识，避免整条 query 因一个 token 失败
local function get_operator_query(ft)
    if operator_queries[ft] ~= nil then return operator_queries[ft] end
    if no_operator_ft[ft] then
        operator_queries[ft] = false
        return false
    end
    local patterns = {}
    for _, token in ipairs(operator_tokens) do
        local ok = pcall(vim.treesitter.query.parse, ft, '("' .. token .. '" @vimore.operator)')
        if ok then table.insert(patterns, '("' .. token .. '" @vimore.operator)') end
    end
    local ok, query = pcall(vim.treesitter.query.parse, ft, table.concat(patterns, '\n'))
    if not ok or #patterns == 0 then query = false end
    operator_queries[ft] = query
    return query
end

local function apply_query(bufnr, query, ns, hl, priority)
    local root = vim.treesitter.get_parser(bufnr):parse()[1]:root()
    for _, node in query:iter_captures(root, bufnr, 0, -1) do
        local r1, c1, r2, c2 = node:range()
        pcall(api.nvim_buf_set_extmark, bufnr, ns, r1, c1, {
            end_row = r2,
            end_col = c2,
            hl_group = hl,
            priority = priority,
        })
    end
end

function M.apply(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    api.nvim_buf_clear_namespace(bufnr, ns_pointer, 0, -1)
    api.nvim_buf_clear_namespace(bufnr, ns_operator, 0, -1)

    local ft = vim.bo[bufnr].filetype
    if ft == '' then return end
    if not vim.treesitter.get_parser(bufnr, ft) then return end

    local op_query = get_operator_query(ft)
    if op_query then apply_query(bufnr, op_query, ns_operator, 'Operator', 150) end

    if ft == 'c' or ft == 'cpp' then
        local ptr_query = get_pointer_query(ft)
        if ptr_query then apply_query(bufnr, ptr_query, ns_pointer, 'VimorePointer', 200) end
    end
end

function M.attach()
    local group = api.nvim_create_augroup('VimorePointer', { clear = true })
    api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'InsertLeave', 'BufWritePost' }, {
        group = group,
        callback = function(args)
            vim.schedule(function() M.apply(args.buf) end)
        end,
    })
end

return M
