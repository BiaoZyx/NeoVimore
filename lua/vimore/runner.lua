-- ============================================================
-- 18. 运行、调试、格式化、检查
-- ============================================================
local M = {}

local fn = vim.fn

-- 调试当前文件
function M.debug()
    pcall(vim.cmd.write)
    local ft = vim.bo.filetype
    if ft == 'python' then
        vim.cmd('!python3 -m pdb %')
    elseif ft == 'c' or ft == 'cpp' then
        vim.cmd('!g++ % -g -o %< && gdb ./%<')
    elseif ft == 'go' then
        vim.cmd('!dlv debug %')
    else
        vim.api.nvim_echo({ { 'vimore: 调试不支持的文件类型: ' .. ft, 'WarningMsg' } }, false, {})
    end
end

local function run_fmt(cmd)
    return fn.system(cmd)
end

-- 自动格式化：优先用各语言的格式化工具，没有则 gg=G
function M.format()
    pcall(vim.cmd.write)
    local pos = fn.getpos('.')
    local ft = vim.bo.filetype
    local formatted = false
    local output = ''
    local file = fn.shellescape(fn.expand('%'))

    if ft == 'python' then
        if fn.executable('black') == 1 then
            output = run_fmt('black --skip-string-normalization ' .. file .. ' 2>&1')
            formatted = true
        elseif fn.executable('autopep8') == 1 then
            output = run_fmt('autopep8 -i --aggressive --max-line-length=120 ' .. file .. ' 2>&1')
            formatted = true
        end
        if formatted and fn.executable('isort') == 1 then
            output = output .. run_fmt('isort ' .. file .. ' 2>&1')
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    elseif ft == 'go' then
        if fn.executable('gofmt') == 1 then
            output = run_fmt('gofmt -w ' .. file .. ' 2>&1')
            formatted = true
        end
        if formatted and fn.executable('goimports') == 1 then
            output = output .. run_fmt('goimports -w ' .. file .. ' 2>&1')
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    elseif ft == 'javascript' or ft == 'typescript' then
        if fn.executable('prettier') == 1 then
            output = run_fmt('prettier --write ' .. file .. ' 2>&1')
            formatted = true
        elseif fn.executable('eslint') == 1 then
            output = run_fmt('eslint --fix ' .. file .. ' 2>&1')
            formatted = true
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    elseif ft == 'c' or ft == 'cpp' then
        if fn.executable('clang-format') == 1 then
            output = run_fmt('clang-format -i ' .. file .. ' 2>&1')
            formatted = true
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    elseif ft == 'java' then
        if fn.executable('astyle') == 1 then
            output = run_fmt('astyle --style=java --suffix=none ' .. file .. ' 2>&1')
            formatted = true
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    elseif ft == 'json' then
        if fn.executable('prettier') == 1 then
            output = run_fmt('prettier --write ' .. file .. ' 2>&1')
            formatted = true
        elseif fn.executable('python3') == 1 then
            local tmp = fn.shellescape(fn.expand('%:r')) .. '.tmp'
            output = run_fmt('python3 -m json.tool ' .. file .. ' > ' .. tmp .. ' && mv ' .. tmp .. ' ' .. file .. ' 2>&1')
            formatted = true
        end
        if not formatted then
            vim.cmd('normal gg=G')
        end
    else
        vim.cmd('normal gg=G')
    end

    -- 重载文件，恢复光标
    pcall(vim.cmd, 'e!')
    fn.setpos('.', pos)

    -- 显示输出
    if output == '' then
        vim.api.nvim_echo({ { '格式化完成', 'ModeMsg' } }, false, {})
    else
        vim.api.nvim_echo({ { output } }, false, {})
    end
end

-- 代码检查
function M.check()
    pcall(vim.cmd.write)
    local ft = vim.bo.filetype
    local output = ''
    local file = fn.shellescape(fn.expand('%'))

    if ft == 'python' then
        if fn.executable('pylint') == 1 then
            output = fn.system('pylint ' .. file)
        elseif fn.executable('flake8') == 1 then
            output = fn.system('flake8 ' .. file)
        else
            vim.api.nvim_echo({ { 'vimore: 未找到 Python 代码检查工具', 'WarningMsg' } }, false, {})
            return
        end
    elseif ft == 'javascript' then
        if fn.executable('eslint') == 1 then
            output = fn.system('eslint ' .. file)
        else
            vim.api.nvim_echo({ { 'vimore: 未找到 JavaScript 代码检查工具', 'WarningMsg' } }, false, {})
            return
        end
    else
        vim.api.nvim_echo({ { 'vimore: 代码检查不支持的文件类型: ' .. ft, 'WarningMsg' } }, false, {})
        return
    end

    if output == '' then
        vim.api.nvim_echo({ { '检查通过，没有发现问题', 'ModeMsg' } }, false, {})
    else
        vim.api.nvim_echo({ { output } }, false, {})
    end
end

return M
