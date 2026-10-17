-- ============================================================
-- 11. 终端集成
-- ============================================================
local M = {}

-- 终端模式退出到普通模式
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = '终端模式退出' })

-- 强制透传 Ctrl-C（Neovim 用 chansend 替代 Vim 的 term_sendkeys）
vim.keymap.set('t', '<C-c>', '<Cmd>call chansend(b:terminal_job_id, nr2char(3))<CR>', { desc = '终端透传 Ctrl-C' })

-- 窗口切换
vim.keymap.set('t', '<C-S-h>', '<C-w>h', { desc = '终端切到左窗口' })
vim.keymap.set('t', '<C-S-j>', '<C-w>j', { desc = '终端切到下窗口' })
vim.keymap.set('t', '<C-S-k>', '<C-w>k', { desc = '终端切到上窗口' })
vim.keymap.set('t', '<C-S-l>', '<C-w>l', { desc = '终端切到右窗口' })

-- 终端复制（退出终端模式后复制到系统剪切板）
vim.keymap.set('t', '<C-S-c>', '<C-\\><C-n>"+yy', { desc = '终端复制行' })
vim.keymap.set('t', '<C-S-v>', '<C-\\><C-n>"+pi', { desc = '终端粘贴' })

-- 打开终端：底部 / 右侧
function M.open(direction)
    if direction == 'horizontal' then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
    else
        vim.cmd('vertical botright terminal')
        vim.cmd('vertical resize ' .. math.floor(vim.o.columns / 3))
    end
    vim.cmd.startinsert()
end

-- 各文件类型的运行命令
function M.run_command()
    local ft = vim.bo.filetype
    local file = vim.fn.expand('%')
    if ft == 'python' then
        return 'python3 ' .. file
    elseif ft == 'go' then
        return 'go run ' .. file
    elseif ft == 'c' then
        return 'gcc ' .. file .. ' -o ' .. vim.fn.expand('%:r') .. ' && ./' .. vim.fn.expand('%:r')
    elseif ft == 'cpp' then
        return 'g++ ' .. file .. ' -o ' .. vim.fn.expand('%:r') .. ' && ./' .. vim.fn.expand('%:r')
    elseif ft == 'javascript' then
        return 'node ' .. file
    elseif ft == 'sh' or ft == 'bash' then
        return 'bash ' .. file
    elseif ft == 'lua' then
        return 'lua ' .. file
    elseif ft == 'rust' then
        return 'cargo run'
    end
    return ''
end

-- 找到最新的终端 buffer（bufnr 越大越新）
local function find_latest_terminal()
    local term_bufs = {}
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if vim.bo[info.bufnr].buftype == 'terminal' then
            table.insert(term_bufs, info.bufnr)
        end
    end
    -- 也扫一遍未列出的 terminal buffer
    for buf = 1, vim.fn.bufnr('$') do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
            local found = false
            for _, b in ipairs(term_bufs) do
                if b == buf then found = true break end
            end
            if not found then table.insert(term_bufs, buf) end
        end
    end
    if #term_bufs == 0 then
        return -1
    end
    return math.max(unpack(term_bufs))
end

local function focus_or_open_terminal()
    local term_buf = find_latest_terminal()
    if term_buf == -1 then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
        return
    end
    local wins = vim.fn.win_findbuf(term_buf)
    if #wins == 0 then
        -- buffer 存在但窗口关了，重新打开
        vim.cmd('botright split | buffer ' .. term_buf)
        vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
    else
        vim.api.nvim_set_current_win(wins[1])
    end
end

-- 在最新终端里运行当前文件
function M.run_in_latest()
    local cmd = M.run_command()
    if cmd == '' then
        vim.api.nvim_echo({ { '不支持的文件类型: ' .. vim.bo.filetype, 'WarningMsg' } }, false, {})
        return
    end
    pcall(vim.cmd.write)

    focus_or_open_terminal()
    vim.cmd.startinsert()

    -- 优先 chansend 直接写入终端 pty（可靠，不受输入队列时序影响）
    local job = vim.b.terminal_job_id
    if job then
        vim.fn.chansend(job, cmd .. '\r')
    else
        local cr = vim.api.nvim_replace_termcodes('<CR>', true, false, true)
        vim.api.nvim_feedkeys(cmd .. cr, 'n', false)
    end
end

-- 切换 / 关闭终端
function M.toggle()
    local term_buf = -1
    for buf = 1, vim.fn.bufnr('$') do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
            term_buf = buf
            break
        end
    end

    if term_buf == -1 then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
        vim.cmd.startinsert()
        return
    end

    local wins = vim.fn.win_findbuf(term_buf)
    if #wins == 0 then
        vim.cmd('botright split | buffer ' .. term_buf)
        vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
        vim.cmd.startinsert()
    else
        vim.api.nvim_win_close(wins[1], true)
    end
end

return M
