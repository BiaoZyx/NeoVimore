-- ============================================================
-- 20. 文件头自动生成
-- ============================================================
local M = {}

local ext_ft = {
    py = 'python', go = 'go', sh = 'sh', bash = 'sh',
    c = 'c', cpp = 'cpp', cc = 'cpp', h = 'c', hpp = 'cpp',
    java = 'java', js = 'javascript', ts = 'typescript',
    rs = 'rust', lua = 'lua',
}

local function current_ft()
    if vim.bo.filetype ~= '' then
        return vim.bo.filetype
    end
    -- BufNewFile 阶段 filetype 可能还没检测到，回退到扩展名
    return ext_ft[vim.fn.expand('%:e')] or ''
end

function M.set_title()
    if vim.fn.line('$') > 1 and vim.fn.getline(1) ~= '' then
        return
    end

    local date = os.date('%Y-%m-%d %H:%M:%S')
    local author = vim.g.author or ''
    local email = vim.g.email or ''
    local ft = current_ft()
    local api = vim.api

    if ft == 'python' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '#!/usr/bin/env python3',
            '# -*- coding: utf-8 -*-',
            '"""',
            '@Author: ' .. author,
            '@Email:  ' .. email,
            '@Date:   ' .. date,
            '@Description: ',
            '"""',
            '',
        })
    elseif ft == 'lua' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '#!/usr/bin/env lua',
            '-- Author: ' .. author,
            '-- Email:  ' .. email,
            '-- Date:   ' .. date,
            '-- Description: ',
            '',
        })
    elseif ft == 'go' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            'package main',
            '',
            'func main() {',
            '}',
            '',
        })
    elseif ft == 'sh' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '#!/bin/bash',
            '# Author: ' .. author,
            '# Email:  ' .. email,
            '# Date:   ' .. date,
            '# Description: ',
            '',
        })
    elseif ft == 'c' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '/*************************************************************************',
            ' * @file:   ' .. vim.fn.expand('%'),
            ' * @author: ' .. author,
            ' * @email:  ' .. email,
            ' * @date:   ' .. date,
            ' * @description: ',
            ' ************************************************************************/',
            '',
        })
    elseif ft == 'cpp' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '/*************************************************************************',
            ' * @file:   ' .. vim.fn.expand('%'),
            ' * @author: ' .. author,
            ' * @email:  ' .. email,
            ' * @date:   ' .. date,
            ' * @description: ',
            ' ************************************************************************/',
            '',
        })
    elseif ft == 'java' then
        local class = vim.fn.expand('%:r'):match('([^/\\]+)$') or ''
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '/*',
            ' * @file:   ' .. vim.fn.expand('%'),
            ' * @author: ' .. author,
            ' * @email:  ' .. email,
            ' * @date:   ' .. date,
            ' */',
            '',
            'public class ' .. class,
            '{',
            '    public static void main(String[] args) {',
            '        System.out.println("Hello, World!");',
            '    }',
            '}',
            '',
        })
    elseif ft == 'javascript' or ft == 'typescript' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '/**',
            ' * @file:   ' .. vim.fn.expand('%'),
            ' * @author: ' .. author,
            ' * @email:  ' .. email,
            ' * @date:   ' .. date,
            ' */',
            '',
        })
    elseif ft == 'rust' then
        api.nvim_buf_set_lines(0, 0, -1, false, {
            '//',
            '// @file:   ' .. vim.fn.expand('%'),
            '// @author: ' .. author,
            '// @email:  ' .. email,
            '// @date:   ' .. date,
            '//',
            '',
        })
    else
        return
    end
    vim.cmd('normal! G')
end

vim.api.nvim_create_autocmd('BufNewFile', {
    group = vim.api.nvim_create_augroup('VimoreHeader', { clear = true }),
    pattern = { '*.py', '*.go', '*.sh', '*.c', '*.cpp', '*.h', '*.hpp', '*.java', '*.js', '*.ts', '*.rs', '*.lua' },
    callback = M.set_title,
})

return M
