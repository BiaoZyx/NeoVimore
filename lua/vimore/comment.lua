-- ============================================================
-- 10. 快速注释
-- ============================================================
local M = {}

-- 各文件类型注释符号（可由用户覆盖 vim.g.comment_map）
if vim.g.comment_map == nil then
    vim.g.comment_map = {
        python = '# ', sh = '# ', bash = '# ', zsh = '# ',
        lua = '-- ', sql = '-- ',
        c = '// ', cpp = '// ', java = '// ', javascript = '// ',
        typescript = '// ', go = '// ', rust = '// ', csharp = '// ',
        php = '// ', json = '// ', scss = '// ',
        vim = '" ', vimrc = '" ',
        html = '<!-- ', markdown = '<!-- ',
        css = '/* ',
        yaml = '# ', yml = '# ', ruby = '# ', perl = '# ',
        tex = '% ',
    }
end

local function get_comment_str()
    return vim.g.comment_map[vim.bo.filetype] or '# '
end

local function get_comment_end_str()
    local ft = vim.bo.filetype
    if ft == 'html' or ft == 'markdown' then
        return ' -->'
    elseif ft == 'css' then
        return ' */'
    end
    return ''
end

-- Lua 模式的转义符是 %，不是 \。
-- 必须转义的元字符：^ $ ( ) % . [ ] * + - ?
-- 重点：'-' 不转义会被当懒惰量词，"--" 变成 "^-*"，匹配任意行首。
local function escape_re(s)
    return (s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

-- 转义 gsub 替换串里的 %
local function escape_rep(s)
    return (s:gsub('%%', '%%%%'))
end

-- 当前行：注释 / 取消注释
function M.toggle()
    local line = vim.api.nvim_get_current_line()
    local comment = get_comment_str()
    local comment_end = get_comment_end_str()
    local symbol = comment:gsub('%s+$', '')
    local symbol_re = escape_re(symbol)
    local end_re = escape_re(comment_end)
    local trimmed = line:gsub('^%s*', '')

    if trimmed:find('^' .. symbol_re) then
        -- 取消注释
        if comment_end ~= '' then
            line = line:gsub('(%s*)' .. symbol_re .. '%s*(.-)' .. end_re .. '$', '%1%2', 1)
        else
            line = line:gsub('(%s*)' .. symbol_re .. '%s*', '%1', 1)
        end
        vim.api.nvim_set_current_line(line)
    else
        -- 添加注释
        if comment_end ~= '' then
            line = line:gsub('^(%s*)(.*)$', '%1' .. escape_rep(comment) .. '%2' .. escape_rep(comment_end), 1)
        else
            line = line:gsub('^(%s*)(.*)$', '%1' .. escape_rep(comment) .. '%2', 1)
        end
        vim.api.nvim_set_current_line(line)
    end
end

-- 可视选区：有一行没注释 → 全部加注释；全都注释了 → 全部去掉注释
function M.toggle_visual()
    local comment = get_comment_str()
    local comment_end = get_comment_end_str()
    local symbol = comment:gsub('%s+$', '')
    local symbol_re = escape_re(symbol)
    local end_re = escape_re(comment_end)

    -- 优先用 menu.lua 传入的行号，回退到 '< '>'
    local start_line = vim.g.vimore_visual_start
    local end_line = vim.g.vimore_visual_end
    if not start_line or start_line < 1 then
        start_line = vim.fn.line("'<")
        end_line = vim.fn.line("'>")
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
    end
    if start_line < 1 then
        return
    end

    local all_commented = true
    for l = start_line, end_line do
        local trimmed = vim.fn.getline(l):gsub('^%s*', '')
        if trimmed ~= '' and not trimmed:find('^' .. symbol_re) then
            all_commented = false
            break
        end
    end

    for l = start_line, end_line do
        local line = vim.fn.getline(l)
        local indent = line:match('^%s*')
        local body = line:sub(#indent + 1)

        if all_commented then
            -- 取消注释
            if comment_end ~= '' then
                body = body:gsub('^' .. symbol_re .. '%s*(.-)' .. end_re .. '$', '%1', 1)
            else
                body = body:gsub('^' .. symbol_re .. '%s*', '', 1)
            end
        else
            -- 加注释，空行跳过
            if body ~= '' then
                body = comment .. body
                if comment_end ~= '' then
                    body = body .. comment_end
                end
            end
        end

        vim.fn.setline(l, indent .. body)
    end
end

-- 供 Leader 菜单调用：可视选区来的走批量逻辑
function M.toggle_smart()
    if vim.g.vimore_from_visual then
        M.toggle_visual()
    else
        M.toggle()
    end
end

return M
