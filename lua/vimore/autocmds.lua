-- ============================================================
-- 21. 自动命令
-- ============================================================
local group = vim.api.nvim_create_augroup('VimoreAutocmds', { clear = true })

-- 文件在外部被修改时自动重载
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
    group = group,
    command = 'silent! checktime',
})

-- 进入 buffer 时把工作目录切到文件所在目录
vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
        local dir = vim.fn.expand('%:p:h')
        if vim.fn.isdirectory(dir) == 1 then
            vim.cmd('silent! lcd ' .. vim.fn.fnameescape(dir))
        end
    end,
})

-- 打开文件时光标恢复到上次位置
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 文档格式：软换行、词边界换行、不显示折行提示符
-- 其他格式：不折行、显示 ↪
local text_fts = {
  markdown = true, text = true, org = true, gitcommit = true,
  rst = true, asciidoc = true, tex = true,
}

vim.api.nvim_create_augroup("SoftWrapForText", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter" }, {
  group = "SoftWrapForText",
  callback = function()
    vim.schedule(function()
      local ft = vim.bo.filetype
      if text_fts[ft] then
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.showbreak = ""
      else
        vim.opt_local.wrap = false
        vim.opt_local.showbreak = "↪"
      end
    end)
  end,
})

return {}
