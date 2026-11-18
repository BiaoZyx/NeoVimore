-- ============================================================
-- 终端集成
-- ============================================================
local M = {}

local fn = vim.fn
local api = vim.api

-- 终端模式退出到普通模式
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = '终端模式退出' })

-- 强制透传 Ctrl-C（Neovim 用 chansend 替代 Vim 的 term_sendkeys）
vim.keymap.set('t', '<C-c>', function()
    local job = vim.b.terminal_job_id
    if job then fn.chansend(job, '\3') end
end, { desc = '终端透传 Ctrl-C' })

-- 窗口切换
-- Neovim 在终端模式下不会把 <C-w> 当窗口前缀，而是原样交给 shell，
-- 所以必须显式映射；RHS 先 <C-\><C-n> 回到普通模式再执行 wincmd。
local function win_move(dir) return '<C-\\><C-n><C-w>' .. dir end
for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
    vim.keymap.set('t', '<C-w>' .. dir, win_move(dir), { desc = '终端切换窗口 ' .. dir })
    -- foot 对 Ctrl+Shift+H/J/K/L 只发普通控制字节，Neovim 认成 <C-S-*>
    vim.keymap.set('t', '<C-S-' .. dir .. '>', win_move(dir), { desc = '终端切换窗口 ' .. dir })
end

-- 终端复制 / 粘贴：直接和系统剪切板寄存器打交道，不依赖终端 buffer 可改性
vim.keymap.set('t', '<C-S-c>', function()
    fn.setreg('+', fn.getline('.'))
    vim.notify('已复制当前行到系统剪切板', vim.log.levels.INFO)
end, { desc = '终端复制行' })
vim.keymap.set('t', '<C-S-v>', function()
    local job = vim.b.terminal_job_id
    if job then fn.chansend(job, fn.getreg('+')) end
end, { desc = '终端粘贴' })

-- 打开终端：底部 / 右侧
function M.open(direction)
    if direction == 'horizontal' then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.max(5, math.floor(vim.o.lines / 3)))
    else
        vim.cmd('vertical botright terminal')
        vim.cmd('vertical resize ' .. math.max(20, math.floor(vim.o.columns / 3)))
    end
    vim.cmd.startinsert()
end

local function cd_prefix()
    local dir = fn.expand('%:p:h')
    if dir == '' then return '' end
    return 'cd ' .. fn.shellescape(dir) .. ' && '
end

-- 各文件类型的运行命令
function M.run_command()
    local file = fn.shellescape(fn.expand('%:p'))
    local ft = vim.bo.filetype
    local prefix = cd_prefix()

    if ft == 'python' then
        return prefix .. 'python3 ' .. file
    elseif ft == 'go' then
        return prefix .. 'go run ' .. file
    elseif ft == 'c' then
        local out = fn.shellescape(fn.expand('%:p:r'))
        return prefix .. 'gcc ' .. file .. ' -o ' .. out .. ' && ' .. out
    elseif ft == 'cpp' then
        local out = fn.shellescape(fn.expand('%:p:r'))
        return prefix .. 'g++ ' .. file .. ' -o ' .. out .. ' && ' .. out
    elseif ft == 'javascript' then
        return prefix .. 'node ' .. file
    elseif ft == 'java' then
        return prefix .. 'java ' .. file
    elseif ft == 'sh' or ft == 'bash' then
        return prefix .. 'bash ' .. file
    elseif ft == 'lua' then
        return prefix .. 'lua ' .. file
    elseif ft == 'rust' then
        return prefix .. 'cargo run'
    end
    return ''
end

-- 找到最新的终端 buffer（bufnr 越大越新）
local function find_latest_terminal()
    local latest = -1
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then latest = math.max(latest, buf) end
    end
    return latest
end

local function open_terminal_window(term_buf)
    vim.cmd('botright split')
    vim.cmd('buffer ' .. term_buf)
    vim.cmd('resize ' .. math.max(5, math.floor(vim.o.lines / 3)))
end

local function focus_or_open_terminal()
    local term_buf = find_latest_terminal()
    if term_buf == -1 then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.max(5, math.floor(vim.o.lines / 3)))
        return
    end

    local wins = fn.win_findbuf(term_buf)
    if #wins == 0 then
        open_terminal_window(term_buf)
    else
        api.nvim_set_current_win(wins[1])
    end
end

-- 在最新终端里运行当前文件
function M.run_in_latest()
    local cmd = M.run_command()
    if cmd == '' then
        vim.api.nvim_echo({ { '不支持的文件类型: ' .. vim.bo.filetype, 'WarningMsg' } }, false, {})
        return
    end

    if vim.bo.modified then
        local ok = pcall(vim.cmd.write)
        if not ok then
            vim.api.nvim_echo({ { '保存失败，已取消运行', 'ErrorMsg' } }, false, {})
            return
        end
    end

    focus_or_open_terminal()
    vim.cmd.startinsert()

    -- 优先 chansend 直接写入终端 pty（可靠，不受输入队列时序影响）
    local job = vim.b.terminal_job_id
    if job then
        fn.chansend(job, cmd .. '\r')
    else
        local cr = api.nvim_replace_termcodes('<CR>', true, false, true)
        api.nvim_feedkeys(cmd .. cr, 'n', false)
    end
end

-- 切换 / 关闭终端
function M.toggle()
    local term_buf = find_latest_terminal()

    if term_buf == -1 then
        vim.cmd('botright terminal')
        vim.cmd('resize ' .. math.max(5, math.floor(vim.o.lines / 3)))
        vim.cmd.startinsert()
        return
    end

    local wins = fn.win_findbuf(term_buf)
    if #wins == 0 then
        open_terminal_window(term_buf)
        vim.cmd.startinsert()
    else
        api.nvim_win_close(wins[1], true)
    end
end

return M
