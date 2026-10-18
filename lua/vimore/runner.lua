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

    local function run(cmd)
        output = output .. fn.system(cmd .. ' 2>&1')
        formatted = true
    end

    local function has(exe)
        return fn.executable(exe) == 1
    end

    if ft == 'python' then
        if has('black') then
            run('black --skip-string-normalization ' .. file)
        elseif has('autopep8') then
            run('autopep8 -i --aggressive --max-line-length=120 ' .. file)
        elseif has('ruff') then
            run('ruff format ' .. file)
        end
        if formatted and has('isort') then
            run('isort ' .. file)
        end
    elseif ft == 'go' then
        if has('gofmt') then run('gofmt -w ' .. file) end
        if formatted and has('goimports') then run('goimports -w ' .. file) end
    elseif ft == 'rust' then
        if has('rustfmt') then
            run('rustfmt ' .. file)
        elseif has('cargo') then
            run('cargo fmt')
        end
    elseif ft == 'lua' then
        if has('stylua') then
            run('stylua ' .. file)
        end
    elseif ft == 'javascript' or ft == 'typescript'
        or ft == 'javascriptreact' or ft == 'typescriptreact' then
        if has('prettier') then
            run('prettier --write ' .. file)
        elseif has('eslint') then
            run('eslint --fix ' .. file)
        end
    elseif ft == 'json' or ft == 'jsonc' then
        if has('prettier') then
            run('prettier --write ' .. file)
        elseif has('jq') then
            run('jq . ' .. file .. ' > ' .. file .. '.tmp && mv ' .. file .. '.tmp ' .. file)
        elseif has('python3') then
            local tmp = fn.shellescape(fn.expand('%:r')) .. '.tmp'
            run('python3 -m json.tool ' .. file .. ' > ' .. tmp .. ' && mv ' .. tmp .. ' ' .. file)
        end
    elseif ft == 'yaml' or ft == 'yml' then
        if has('prettier') then
            run('prettier --write ' .. file)
        elseif has('yq') then
            run('yq -i ". style=\"\\"\\"" ' .. file)
        end
    elseif ft == 'markdown' then
        if has('prettier') then
            run('prettier --write ' .. file)
        elseif has('mdformat') then
            run('mdformat ' .. file)
        end
    elseif ft == 'html' or ft == 'css' or ft == 'scss' or ft == 'less' then
        if has('prettier') then
            run('prettier --write ' .. file)
        end
    elseif ft == 'c' or ft == 'cpp' or ft == 'cuda' then
        if has('clang-format') then
            run('clang-format -i ' .. file)
        end
    elseif ft == 'java' then
        if has('google-java-format') then
            run('google-java-format -i ' .. file)
        elseif has('astyle') then
            run('astyle --style=java --suffix=none ' .. file)
        end
    elseif ft == 'sh' or ft == 'bash' then
        if has('shfmt') then
            run('shfmt -w ' .. file)
        end
    elseif ft == 'toml' then
        if has('taplo') then
            run('taplo format ' .. file)
        end
    elseif ft == 'xml' then
        if has('xmllint') then
            run('xmllint --format ' .. file .. ' -o ' .. file)
        end
    elseif ft == 'sql' then
        if has('sqlfluff') then
            run('sqlfluff fix ' .. file)
        elseif has('sqlformat') then
            run('sqlformat -r -k upper -i indent ' .. file .. ' -o ' .. file)
        end
    elseif ft == 'ruby' then
        if has('rubocop') then
            run('rubocop -a ' .. file)
        end
    elseif ft == 'php' then
        if has('php-cs-fixer') then
            run('php-cs-fixer fix ' .. file)
        elseif has('pint') then
            run('pint ' .. file)
        end
    elseif ft == 'zig' then
        if has('zig') then
            run('zig fmt ' .. file)
        end
    elseif ft == 'nix' then
        if has('alejandra') then
            run('alejandra ' .. file)
        elseif has('nixpkgs-fmt') then
            run('nixpkgs-fmt ' .. file)
        end
    elseif ft == 'cmake' then
        if has('cmake-format') then
            run('cmake-format -i ' .. file)
        end
    end

    if not formatted then
        vim.cmd('normal gg=G')
    end

    pcall(vim.cmd, 'e!')
    fn.setpos('.', pos)

    if output == '' then
        vim.api.nvim_echo({ { formatted and '格式化完成' or '已用 gg=G 基础缩进', 'ModeMsg' } }, false, {})
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
