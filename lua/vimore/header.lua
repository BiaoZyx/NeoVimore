-- ============================================================
-- 文件头自动生成
-- Doxygen 风格：@file / @author / @email / @date / @brief
-- 许可证统一放在根目录 LICENSE，文件头里不重复贴长文本。
-- 作者/邮箱留空时不写对应行。
-- ============================================================
local M = {}

local fn = vim.fn
local api = vim.api

local ext_ft = {
    py = 'python',
    go = 'go',
    sh = 'sh',
    bash = 'sh',
    c = 'c',
    cc = 'cpp',
    cpp = 'cpp',
    h = 'c',
    hpp = 'cpp',
    java = 'java',
    js = 'javascript',
    ts = 'typescript',
    rs = 'rust',
    lua = 'lua',
}

local function current_ft()
    if vim.bo.filetype ~= '' then return vim.bo.filetype end
    -- BufNewFile 阶段 filetype 可能还没检测到，回退到扩展名
    return ext_ft[fn.expand('%:e'):lower()] or ''
end

local function go_package()
    local dir = fn.fnamemodify(fn.expand('%:p:h'), ':t'):lower()
    local name = dir:gsub('[^%w_]', '_')
    if name == '' or not name:match('^[%a_]') then return 'main' end
    return name
end

local function java_class()
    local name = fn.expand('%:r'):match('([^/\\]+)$') or ''
    if name == '' or not name:match('^[%a_][%w_]*$') then return 'Main' end
    return name
end

-- 统一的 Doxygen 字段块；prefix 决定每行的注释前缀
local function meta_lines(prefix, file, date)
    local lines = { prefix .. '@file    ' .. file }
    local author = vim.g.author or ''
    local email = vim.g.email or ''
    if author ~= '' then table.insert(lines, prefix .. '@author  ' .. author) end
    if email ~= '' then table.insert(lines, prefix .. '@email   ' .. email) end
    table.insert(lines, prefix .. '@date    ' .. date)
    table.insert(lines, prefix .. '@brief   ')
    return lines
end

function M.set_title()
    if fn.line('$') > 1 and fn.getline(1) ~= '' then return end

    -- 创建日期只到天；时刻交给 git，不写进每个文件
    local date = os.date('%Y-%m-%d')
    local ft = current_ft()
    local file = fn.expand('%:t')
    local lines = {}

    if ft == 'python' then
        -- Python 3 源码默认 UTF-8（PEP 3120），不再需要 coding 声明
        lines = { '#!/usr/bin/env python3', '"""' }
        vim.list_extend(lines, meta_lines('', file, date))
        vim.list_extend(lines, { '"""', '' })
    elseif ft == 'lua' then
        lines = { '#!/usr/bin/env lua', '--[[' }
        vim.list_extend(lines, meta_lines('', file, date))
        vim.list_extend(lines, { ']]', '' })
    elseif ft == 'sh' or ft == 'bash' then
        lines = { '#!/bin/sh' }
        vim.list_extend(lines, meta_lines('# ', file, date))
        table.insert(lines, '')
    elseif ft == 'go' then
        lines = meta_lines('// ', file, date)
        table.insert(lines, '')
        local pkg = go_package()
        table.insert(lines, 'package ' .. pkg)
        if pkg == 'main' then
            vim.list_extend(lines, { '', 'func main() {', '}', '' })
        else
            table.insert(lines, '')
        end
    elseif ft == 'c' or ft == 'cpp' then
        lines = { '/**' }
        vim.list_extend(lines, meta_lines(' * ', file, date))
        vim.list_extend(lines, { ' */', '' })
    elseif ft == 'java' then
        lines = { '/**' }
        vim.list_extend(lines, meta_lines(' * ', file, date))
        vim.list_extend(lines, {
            ' */',
            '',
            'public class ' .. java_class(),
            '{',
            '}',
            '',
        })
    elseif ft == 'javascript' or ft == 'typescript' then
        lines = { '/**' }
        vim.list_extend(lines, meta_lines(' * ', file, date))
        vim.list_extend(lines, { ' */', '' })
    elseif ft == 'rust' then
        lines = meta_lines('//! ', file, date)
        table.insert(lines, '')
    else
        return
    end

    api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('normal! G')
end

vim.api.nvim_create_autocmd('BufNewFile', {
    group = vim.api.nvim_create_augroup('VimoreHeader', { clear = true }),
    pattern = {
        '*.py',
        '*.go',
        '*.sh',
        '*.bash',
        '*.c',
        '*.cc',
        '*.cpp',
        '*.h',
        '*.hpp',
        '*.java',
        '*.js',
        '*.ts',
        '*.rs',
        '*.lua',
    },
    callback = M.set_title,
})

return M
