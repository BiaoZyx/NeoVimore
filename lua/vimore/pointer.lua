-- ============================================================
-- 跨语言语义着色补丁
-- 不依赖 treesitter highlighter / LSP semantic tokens，直接用
-- treesitter parser 给各类语法节点打 extmark，让不同语言的
-- 注释/字符串/数字/关键字/运算符/指针颜色保持一致。
-- ============================================================
local M = {}

local api = vim.api
local ns_pointer = api.nvim_create_namespace('vimore.pointer')
local ns_operator = api.nvim_create_namespace('vimore.operator')
local ns_semantic = api.nvim_create_namespace('vimore.semantic')

local pattern_cache = {}
local operator_queries = {}
local semantic_queries = {}
local pointer_queries = {}

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

local keyword_tokens = {
    'if',
    'else',
    'elif',
    'elseif',
    'for',
    'while',
    'do',
    'break',
    'continue',
    'return',
    'function',
    'func',
    'def',
    'class',
    'struct',
    'enum',
    'interface',
    'import',
    'from',
    'as',
    'try',
    'catch',
    'except',
    'finally',
    'throw',
    'raise',
    'switch',
    'case',
    'default',
    'new',
    'delete',
    'this',
    'self',
    'let',
    'const',
    'var',
    'fn',
    'pub',
    'fn',
    'type',
    'package',
    'goto',
    'sizeof',
    'static',
    'inline',
    'async',
    'await',
    'yield',
    'in',
    'is',
    'not',
    'and',
    'or',
}

-- 这些文件类型跳过运算符着色，避免把列表符号/锚点误染
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

local semantic_hl = {
    ['vimore.comment'] = 'Comment',
    ['vimore.string'] = 'String',
    ['vimore.number'] = 'Number',
    ['vimore.keyword'] = 'Keyword',
}

local semantic_patterns = {
    '(comment) @vimore.comment',
    '(string) @vimore.string',
    '(string_literal) @vimore.string',
    '(interpreted_string_literal) @vimore.string',
    '(raw_string_literal) @vimore.string',
    '(char_literal) @vimore.string',
    '(integer) @vimore.number',
    '(float) @vimore.number',
    '(number) @vimore.number',
}

local function pattern_exists(ft, pattern)
    local key = ft .. '|' .. pattern
    if pattern_cache[key] ~= nil then return pattern_cache[key] end
    local ok = pcall(vim.treesitter.query.parse, ft, pattern)
    pattern_cache[key] = ok
    return ok
end

local function build_query(ft, patterns)
    local valid = {}
    for _, p in ipairs(patterns) do
        if pattern_exists(ft, p) then table.insert(valid, p) end
    end
    if #valid == 0 then return false end
    local ok, query = pcall(vim.treesitter.query.parse, ft, table.concat(valid, '\n'))
    if not ok then return false end
    return query
end

local function get_operator_query(ft)
    if operator_queries[ft] ~= nil then return operator_queries[ft] end
    if no_operator_ft[ft] then
        operator_queries[ft] = false
        return false
    end
    local patterns = {}
    for _, token in ipairs(operator_tokens) do
        local p = '("' .. token .. '" @vimore.operator)'
        if pattern_exists(ft, p) then table.insert(patterns, p) end
    end
    local query = build_query(ft, patterns)
    operator_queries[ft] = query
    return query
end

local function get_semantic_query(ft)
    if semantic_queries[ft] ~= nil then return semantic_queries[ft] end
    local patterns = vim.deepcopy(semantic_patterns)
    for _, token in ipairs(keyword_tokens) do
        local p = '("' .. token .. '" @vimore.keyword)'
        if pattern_exists(ft, p) then table.insert(patterns, p) end
    end
    local query = build_query(ft, patterns)
    semantic_queries[ft] = query
    return query
end

local function get_pointer_query(ft)
    if pointer_queries[ft] ~= nil then return pointer_queries[ft] end
    local query = build_query(ft, {
        '(pointer_declarator "*" @vimore.pointer)',
        '(pointer_expression "*" @vimore.pointer)',
    })
    pointer_queries[ft] = query
    return query
end

local function apply_query(bufnr, query, ns, hl_or_map, priority)
    local root = vim.treesitter.get_parser(bufnr):parse()[1]:root()
    local id_to_hl = type(hl_or_map) == 'table' and hl_or_map or nil
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
        local r1, c1, r2, c2 = node:range()
        local hl = id_to_hl and id_to_hl[query.captures[id]] or hl_or_map
        if hl then
            pcall(api.nvim_buf_set_extmark, bufnr, ns, r1, c1, {
                end_row = r2,
                end_col = c2,
                hl_group = hl,
                priority = priority,
            })
        end
    end
end

function M.apply(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    for _, ns in ipairs({ ns_pointer, ns_operator, ns_semantic }) do
        api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end

    local ft = vim.bo[bufnr].filetype
    if ft == '' then return end
    if not vim.treesitter.get_parser(bufnr, ft) then return end

    local sem_query = get_semantic_query(ft)
    if sem_query then apply_query(bufnr, sem_query, ns_semantic, semantic_hl, 100) end

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
