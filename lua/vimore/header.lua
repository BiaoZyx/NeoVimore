-- ============================================================
-- 文件头自动生成
-- 作者/邮箱留空时不写入对应行，避免生成空字段
-- ============================================================
local M = {}

local ext_ft = {
    py = 'python',
    go = 'go',
    sh = 'sh',
    bash = 'sh',
    c = 'c',
    cpp = 'cpp',
    cc = 'cpp',
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
    return ext_ft[vim.fn.expand('%:e')] or ''
end

local function author_lines(prefix)
    local lines = {}
    if (vim.g.author or '') ~= '' then table.insert(lines, prefix .. 'Author: ' .. vim.g.author) end
    if (vim.g.email or '') ~= '' then table.insert(lines, prefix .. 'Email:  ' .. vim.g.email) end
    return lines
end

-- Go 的 package 名不能直接写死成 main：新建 foo.go 时按目录推导，
-- 推导失败再退回 main；只有 main 包才顺手生成 func main。
local function go_package()
    local dir = vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':t')
    local name = dir:lower():gsub('[^%w_]', '_')
    if name == '' or not name:match('^[%a_]') then return 'main' end
    return name
end

local function java_class()
    local name = vim.fn.expand('%:r'):match('([^/\\]+)$') or ''
    if name == '' or not name:match('^[%a_][%w_]*$') then return 'Main' end
    return name
end

function M.set_title()
    if vim.fn.line('$') > 1 and vim.fn.getline(1) ~= '' then return end

    local date = os.date('%Y-%m-%d %H:%M:%S')
    local ft = current_ft()
    local file = vim.fn.expand('%')
    local api = vim.api
    local lines

    if ft == 'python' then
        lines = {
            '#!/usr/bin/env python3',
            '# -*- coding: utf-8 -*-',
            '"""',
        }
        vim.list_extend(lines, author_lines('@'))
        table.insert(lines, '@Date:   ' .. date)
        table.insert(lines, '@Description: ')
        vim.list_extend(lines, { '"""', '' })
    elseif ft == 'lua' then
        lines = { '#!/usr/bin/env lua' }
        vim.list_extend(lines, author_lines('-- '))
        vim.list_extend(lines, {
            '-- Date:   ' .. date,
            '-- Description: ',
            '',
        })
    elseif ft == 'go' then
        lines = {
            '// @file:   ' .. file,
        }
        vim.list_extend(lines, author_lines('// '))
        vim.list_extend(lines, {
            '// @date:   ' .. date,
            '',
            'package ' .. go_package(),
            '',
        })
        if go_package() == 'main' then vim.list_extend(lines, { 'func main() {', '}', '' }) end
    elseif ft == 'sh' or ft == 'bash' then
        lines = { '#!/bin/sh' }
        vim.list_extend(lines, author_lines('# '))
        vim.list_extend(lines, {
            '# Date:   ' .. date,
            '# Description: ',
            '',
        })
    elseif ft == 'c' or ft == 'cpp' then
        lines = {
            '/*************************************************************************',
            ' * @file:   ' .. file,
        }
        vim.list_extend(lines, author_lines(' * '))
        vim.list_extend(lines, {
            ' * @date:   ' .. date,
            ' * @description: ',
            ' ************************************************************************/',
            '',
        })
    elseif ft == 'java' then
        lines = {
            '/*',
            ' * @file:   ' .. file,
        }
        vim.list_extend(lines, author_lines(' * '))
        vim.list_extend(lines, {
            ' * @date:   ' .. date,
            ' */',
            '',
            'public class ' .. java_class(),
            '{',
            '}',
            '',
        })
    elseif ft == 'javascript' or ft == 'typescript' then
        lines = {
            '/**',
            ' * @file:   ' .. file,
        }
        vim.list_extend(lines, author_lines(' * '))
        vim.list_extend(lines, {
            ' * @date:   ' .. date,
            ' */',
            '',
        })
    elseif ft == 'rust' then
        lines = {
            '//',
            '// @file:   ' .. file,
        }
        vim.list_extend(lines, author_lines('// '))
        vim.list_extend(lines, {
            '// @date:   ' .. date,
            '//',
            '',
        })
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
