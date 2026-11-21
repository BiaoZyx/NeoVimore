-- ============================================================
-- C/C++ 指针 * 单独着色
-- 不把所有 Operator 改蓝（那样 =、+ 也会变蓝），只给
-- pointer_declarator / pointer_expression / pointer_type 里的 * 上色。
-- ============================================================
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace('vimore.pointer')

local queries = {}

local function get_query(ft)
    if queries[ft] ~= nil then return queries[ft] end
    local ok, query = pcall(
        vim.treesitter.query.parse,
        ft,
        [[
        (pointer_declarator "*" @vimore.pointer)
        (pointer_expression "*" @vimore.pointer)
    ]]
    )
    if not ok then query = false end
    queries[ft] = query
    return query
end

function M.apply(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local ft = vim.bo[bufnr].filetype
    if ft ~= 'c' and ft ~= 'cpp' then return end
    local query = get_query(ft)
    if not query then return end
    local parser = vim.treesitter.get_parser(bufnr, ft)
    if not parser then return end

    local root = parser:parse()[1]:root()
    for _, node in query:iter_captures(root, bufnr, 0, -1) do
        local r1, c1, r2, c2 = node:range()
        pcall(api.nvim_buf_set_extmark, bufnr, ns, r1, c1, {
            end_row = r2,
            end_col = c2,
            hl_group = 'VimorePointer',
            priority = 200,
        })
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
