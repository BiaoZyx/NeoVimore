-- ============================================================
-- 8. 括号/引号智能补全
-- ============================================================
local M = {}

local api = vim.api

-- 光标前一个字符（0 基字节列）
local function char_before(col, line)
    if col <= 0 then return '' end
    return line:sub(col, col)
end

-- 光标处字符（0 基字节列，即光标后第一个字符）
local function char_at(col, line)
    if col >= #line then return '' end
    return line:sub(col + 1, col + 1)
end

-- 补全左括号：光标后无字符或紧挨右括号时自动配对
function M.smart_pair(left, right)
    local line = api.nvim_get_current_line()
    local col = api.nvim_win_get_cursor(0)[2]

    -- 光标前是反斜杠，直接插入左括号（转义场景）
    if char_before(col, line) == '\\' then
        return left
    end

    if col >= #line or char_at(col, line):match('%s') then
        return left .. right .. '<Left>'
    end
    local nxt = char_at(col, line)
    if nxt:match('[%]%)}>\'"]') then
        return left .. right .. '<Left>'
    end
    return left
end

-- 特殊字符规则：{ 在 C/C++/CSS 不补全；< 仅 HTML/XML 补全；" 在 vim 文件不补全
function M.smart_condition(char)
    local ft = vim.bo.filetype
    if char == '{' then
        if ft == 'c' or ft == 'cpp' or ft == 'css' then
            return char
        end
        return M.smart_pair('{', '}')
    elseif char == '<' then
        if ft == 'xml' or ft == 'html' or ft == 'xhtml' then
            return M.smart_pair('<', '>')
        end
        return char
    elseif char == '"' then
        if ft == 'vim' then
            return char
        end
        return M.smart_quote('"')
    end
    return char
end

-- 引号补全（支持字符串内智能关闭）
function M.smart_quote(quote)
    local line = api.nvim_get_current_line()
    local col = api.nvim_win_get_cursor(0)[2]

    -- 1. 光标前是反斜杠，直接插入（转义场景）
    if char_before(col, line) == '\\' then
        return quote
    end

    -- 2. 光标后已有同款引号，跳过（充当右引号）
    if char_at(col, line) == quote then
        return '<Right>'
    end

    -- 3. 光标后是异类引号或右括号，补全一对（嵌套）
    local nxt = char_at(col, line)
    if nxt ~= '' and (nxt:match('[%]%)}>\'"]')) then
        return quote .. quote .. '<Left>'
    end

    -- 4. 光标后是非空白字符，只插入左引号（续写）
    if nxt ~= '' and not nxt:match('%s') then
        return quote
    end

    -- 5. 行尾或空白：统计未被转义的该引号个数
    local before = line:sub(1, col)
    local quote_count = 0
    for i = 1, #before do
        if before:sub(i, i) == quote then
            if i == 1 or before:sub(i - 1, i - 1) ~= '\\' then
                quote_count = quote_count + 1
            end
        end
    end

    -- 奇数 → 插入右引号（关闭），偶数 → 补全一对
    if quote_count % 2 == 1 then
        return quote
    end
    return quote .. quote .. '<Left>'
end

-- 右括号智能跳出：光标后已是同款符号则直接右移
function M.smart_close(char)
    local line = api.nvim_get_current_line()
    local col = api.nvim_win_get_cursor(0)[2]
    if char_at(col, line) == char then
        return '<Right>'
    end
    return char
end

-- 智能退格：成对删除括号/引号
function M.smart_backspace()
    local line = api.nvim_get_current_line()
    local col = api.nvim_win_get_cursor(0)[2]

    if col <= 0 then
        return '<BS>'
    end

    local before = char_before(col, line)
    local after = char_at(col, line)

    -- 删除成对引号 "" 或 ''
    if (before == '"' and after == '"') or (before == "'" and after == "'") then
        local before_prev = char_before(col - 1, line)
        local after_next = line:sub(col + 2, col + 2)
        if before_prev ~= before and after_next ~= after then
            return '<BS><Del>'
        end
    end

    -- 删除成对括号 () [] {}
    local pairs_map = { ['('] = ')', ['['] = ']', ['{'] = '}', ['<'] = '>' }
    if pairs_map[before] and after == pairs_map[before] then
        local before_prev = char_before(col - 1, line)
        local after_next = line:sub(col + 2, col + 2)
        if before_prev ~= before or after_next ~= after then
            return '<BS><Del>'
        end
    end

    -- 嵌套括号 ((|)) → 删除内层一对
    if col >= 2 and col + 2 <= #line then
        local before2 = line:sub(col - 1, col - 1)
        local after2 = line:sub(col + 2, col + 2)
        if before2 == '(' and after2 == ')' and before == '(' and after == ')' then
            return '<BS><Del>'
        end
    end

    return '<BS>'
end

-- ---------- 映射 ----------
local map_expr = function(keys, fn, desc)
    vim.keymap.set('i', keys, fn, { expr = true, silent = true, desc = desc })
end

map_expr('(', function() return M.smart_pair('(', ')') end, '智能补全 ()')
map_expr('[', function() return M.smart_pair('[', ']') end, '智能补全 []')
map_expr('{', function() return M.smart_pair('{', '}') end, '智能补全 {}')
map_expr('<', function() return M.smart_condition('<') end, '智能补全 <>')
map_expr('"', function() return M.smart_condition('"') end, '智能补全 ""')

map_expr(')', function() return M.smart_close(')') end, '智能跳出 )')
map_expr(']', function() return M.smart_close(']') end, '智能跳出 ]')
map_expr('}', function() return M.smart_close('}') end, '智能跳出 }')
map_expr('>', function() return M.smart_close('>') end, '智能跳出 >')

map_expr('<BS>', function() return M.smart_backspace() end, '智能退格（成对删除）')

return M
