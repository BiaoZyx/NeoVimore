-- ============================================================
-- 自动命令
-- ============================================================
local group = vim.api.nvim_create_augroup('VimoreAutocmds', { clear = true })

-- 文件在外部被修改时自动重载
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
    group = group,
    command = 'silent! checktime',
})

-- 进入 buffer 时把工作目录切到文件所在目录。
-- 这个行为对一些人很方便，但会干扰 :cd / 项目根目录，所以默认关闭。
-- 想要就设 vim.g.vimore_autochdir = true。
vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
        if not vim.g.vimore_autochdir or vim.bo.buftype ~= '' then return end
        local dir = vim.fn.expand('%:p:h')
        if vim.fn.isdirectory(dir) == 1 then vim.cmd('silent! lcd ' .. vim.fn.fnameescape(dir)) end
    end,
})

-- 打开文件时光标恢复到上次位置
vim.api.nvim_create_autocmd('BufReadPost', {
    group = group,
    pattern = '*',
    callback = function()
        if vim.bo.buftype ~= '' then return end
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
    end,
})

-- 复制时短暂高亮，确认 yank 到了哪里（Neovim 内置，无需插件）
vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    callback = function() vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 }) end,
})

-- 终端窗口不显示行号、符号列和光标行，给 shell 更多空间
vim.api.nvim_create_autocmd('TermOpen', {
    group = group,
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
        vim.opt_local.cursorline = false
        vim.opt_local.colorcolumn = ''
        vim.opt_local.list = false -- 终端里不要把空格显示成 ·
        -- 有些终端打开方式不会自动进入终端模式，显式兜底
        pcall(vim.cmd.startinsert)
    end,
})

-- 文档格式：软换行、词边界换行、不显示折行提示符
-- 其他格式：不折行、显示 ↪
local text_fts = {
    markdown = true,
    text = true,
    org = true,
    gitcommit = true,
    rst = true,
    asciidoc = true,
    tex = true,
}

vim.api.nvim_create_augroup('VimoreSoftWrap', { clear = true })
vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter', 'WinEnter' }, {
    group = 'VimoreSoftWrap',
    callback = function()
        vim.schedule(function()
            -- 用 F7 手动切过 wrap 的 buffer 不再被自动规则覆盖
            if vim.b.vimore_wrap_override or vim.bo.buftype ~= '' then return end

            local ft = vim.bo.filetype
            if text_fts[ft] then
                vim.opt_local.wrap = true
                vim.opt_local.linebreak = true
                vim.opt_local.showbreak = ''
                vim.opt_local.colorcolumn = ''
                vim.opt_local.breakindent = true
            else
                vim.opt_local.wrap = false
                vim.opt_local.showbreak = ''
            end
        end)
    end,
})

return {}
