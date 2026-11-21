-- ============================================================
-- 运行、调试、格式化、检查
-- 外部工具一律异步执行，避免卡住编辑器
-- ============================================================
local M = {}

local fn = vim.fn

local function notify(msg, level) vim.notify('vimore: ' .. msg, level or vim.log.levels.INFO) end

local function save_if_needed()
    if not vim.bo.modified then return true end
    local ok = pcall(vim.cmd.write)
    if not ok then notify('Save failed; operation cancelled', vim.log.levels.ERROR) end
    return ok
end

local function file_dir()
    local dir = fn.expand('%:p:h')
    return dir ~= '' and dir or nil
end

-- 在一个临时终端里跑交互式命令；++close 让命令结束后窗口自动关闭
local function run_in_terminal(cmd)
    vim.cmd('botright terminal ++close ' .. cmd)
    require('vimore.terminal').enter()
end

-- ---------- 调试 ----------
function M.debug()
    if not save_if_needed() then return end

    local ft = vim.bo.filetype
    local file = fn.shellescape(fn.expand('%:p'))
    local dir = fn.shellescape(fn.expand('%:p:h'))
    local prefix = 'cd ' .. dir .. ' && '
    local cmd

    if ft == 'python' then
        cmd = prefix .. 'python3 -m pdb ' .. file
    elseif ft == 'c' or ft == 'cpp' then
        local out = fn.shellescape(fn.expand('%:p:r'))
        local compiler = ft == 'c' and 'gcc' or 'g++'
        cmd = prefix .. compiler .. ' ' .. file .. ' -g -o ' .. out .. ' && gdb ' .. out
    elseif ft == 'go' then
        -- dlv debug 调试的是当前目录的 package，不接受单个 .go 文件
        cmd = prefix .. 'dlv debug'
    else
        notify('Debugging not supported for filetype: ' .. ft, vim.log.levels.WARN)
        return
    end

    run_in_terminal(cmd)
end

-- ---------- 格式化 ----------
local function format_candidates(ft, file)
    local list = {}

    if ft == 'python' then
        if fn.executable('black') == 1 then
            list = { 'black --skip-string-normalization ' .. file }
            if fn.executable('isort') == 1 then table.insert(list, 'isort ' .. file) end
            return list
        end
        if fn.executable('ruff') == 1 then
            list = { 'ruff format ' .. file }
            if fn.executable('isort') == 1 then table.insert(list, 'isort ' .. file) end
            return list
        end
        if fn.executable('autopep8') == 1 then return { 'autopep8 -i --aggressive --max-line-length=120 ' .. file } end
    elseif ft == 'go' then
        if fn.executable('gofmt') == 1 then
            list = { 'gofmt -w ' .. file }
            if fn.executable('goimports') == 1 then table.insert(list, 'goimports -w ' .. file) end
            return list
        end
    elseif ft == 'rust' then
        if fn.executable('rustfmt') == 1 then return { 'rustfmt ' .. file } end
        if fn.executable('cargo') == 1 then return { 'cargo fmt' } end
    elseif ft == 'lua' then
        if fn.executable('stylua') == 1 then return { 'stylua ' .. file } end
    elseif
        ft == 'javascript'
        or ft == 'typescript'
        or ft == 'javascriptreact'
        or ft == 'typescriptreact'
        or ft == 'vue'
        or ft == 'svelte'
    then
        if fn.executable('prettier') == 1 then return { 'prettier --write ' .. file } end
        if fn.executable('eslint') == 1 then return { 'eslint --fix ' .. file } end
    elseif ft == 'json' or ft == 'jsonc' then
        if fn.executable('prettier') == 1 then return { 'prettier --write ' .. file } end
        local tmp = fn.shellescape(fn.expand('%:p') .. '.vimore.tmp')
        if fn.executable('jq') == 1 then
            return { 'jq . ' .. file .. ' > ' .. tmp .. ' && mv ' .. tmp .. ' ' .. file }
        end
        if fn.executable('python3') == 1 then
            return { 'python3 -m json.tool ' .. file .. ' > ' .. tmp .. ' && mv ' .. tmp .. ' ' .. file }
        end
    elseif ft == 'yaml' or ft == 'yml' then
        if fn.executable('prettier') == 1 then return { 'prettier --write ' .. file } end
        if fn.executable('yq') == 1 then return { [[yq -i '. style=""' ]] .. file } end
    elseif ft == 'markdown' then
        if fn.executable('prettier') == 1 then return { 'prettier --write ' .. file } end
        if fn.executable('mdformat') == 1 then return { 'mdformat ' .. file } end
    elseif ft == 'html' or ft == 'css' or ft == 'scss' or ft == 'less' then
        if fn.executable('prettier') == 1 then return { 'prettier --write ' .. file } end
    elseif ft == 'c' or ft == 'cpp' or ft == 'cuda' then
        if fn.executable('clang-format') == 1 then
            -- 强制 4 格缩进，避免 clang-format 默认 LLVM 风格的 2 格
            local style = "'{BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}'"
            return { 'clang-format -i --style=' .. style .. ' ' .. file }
        end
    elseif ft == 'java' then
        if fn.executable('google-java-format') == 1 then return { 'google-java-format -i ' .. file } end
        if fn.executable('astyle') == 1 then return { 'astyle --style=java --suffix=none ' .. file } end
    elseif ft == 'sh' or ft == 'bash' then
        if fn.executable('shfmt') == 1 then return { 'shfmt -w ' .. file } end
    elseif ft == 'toml' then
        if fn.executable('taplo') == 1 then return { 'taplo format ' .. file } end
    elseif ft == 'xml' then
        if fn.executable('xmllint') == 1 then return { 'xmllint --format ' .. file .. ' -o ' .. file } end
    elseif ft == 'sql' then
        if fn.executable('sqlfluff') == 1 then return { 'sqlfluff fix ' .. file } end
        if fn.executable('sqlformat') == 1 then
            return { 'sqlformat -r -k upper -i indent ' .. file .. ' -o ' .. file }
        end
    elseif ft == 'ruby' then
        if fn.executable('rubocop') == 1 then return { 'rubocop -a ' .. file } end
    elseif ft == 'php' then
        if fn.executable('php-cs-fixer') == 1 then return { 'php-cs-fixer fix ' .. file } end
        if fn.executable('pint') == 1 then return { 'pint ' .. file } end
    elseif ft == 'zig' then
        if fn.executable('zig') == 1 then return { 'zig fmt ' .. file } end
    elseif ft == 'nix' then
        if fn.executable('alejandra') == 1 then return { 'alejandra ' .. file } end
        if fn.executable('nixpkgs-fmt') == 1 then return { 'nixpkgs-fmt ' .. file } end
    elseif ft == 'cmake' then
        if fn.executable('cmake-format') == 1 then return { 'cmake-format -i ' .. file } end
    end

    return list
end

local function run_queue(cmds, cwd, output, on_done)
    if #cmds == 0 then
        on_done(output)
        return
    end

    local cmd = table.remove(cmds, 1)
    vim.system({ 'sh', '-c', cmd }, { cwd = cwd, text = true }, function(obj)
        vim.schedule(function()
            local out = (obj.stdout or '') .. (obj.stderr or '')
            run_queue(cmds, cwd, output .. out, on_done)
        end)
    end)
end

function M.format()
    if fn.expand('%') == '' then
        notify('Current buffer has no file name; cannot format', vim.log.levels.WARN)
        return
    end
    if not save_if_needed() then return end

    local file = fn.shellescape(fn.expand('%:p'))
    local cmds = format_candidates(vim.bo.filetype, file)
    local pos = fn.getpos('.')

    if #cmds == 0 then
        vim.cmd('normal! gg=G')
        fn.setpos('.', pos)
        notify('No external formatter found; did basic indent with gg=G')
        return
    end

    local cwd = file_dir()
    run_queue(cmds, cwd, '', function(output)
        -- 外部工具直接改磁盘文件，重新读一次
        pcall(vim.cmd, 'silent! checktime')
        pcall(fn.setpos, '.', pos)

        local text = vim.trim(output or '')
        if text ~= '' then
            notify(text, vim.log.levels.INFO)
        else
            notify('Formatting complete')
        end
    end)
end

-- ---------- 代码检查 ----------
local function check_candidates(ft, file)
    if ft == 'python' then
        if fn.executable('ruff') == 1 then return 'ruff check ' .. file end
        if fn.executable('pylint') == 1 then return 'pylint ' .. file end
        if fn.executable('flake8') == 1 then return 'flake8 ' .. file end
    elseif ft == 'javascript' or ft == 'typescript' or ft == 'javascriptreact' or ft == 'typescriptreact' then
        if fn.executable('eslint') == 1 then return 'eslint ' .. file end
    elseif ft == 'go' then
        if fn.executable('go') == 1 then return 'go vet ' .. file end
    elseif ft == 'rust' then
        if fn.executable('cargo') == 1 then return 'cargo check' end
    elseif ft == 'lua' then
        if fn.executable('luac') == 1 then return 'luac -p ' .. file end
    elseif ft == 'sh' or ft == 'bash' then
        if fn.executable('shellcheck') == 1 then return 'shellcheck ' .. file end
    elseif ft == 'c' or ft == 'cpp' then
        local cc = ft == 'c' and 'gcc' or 'g++'
        if fn.executable(cc) == 1 then return cc .. ' -fsyntax-only ' .. file end
    elseif ft == 'json' then
        if fn.executable('jq') == 1 then return 'jq empty ' .. file end
    elseif ft == 'yaml' or ft == 'yml' then
        if fn.executable('yamllint') == 1 then return 'yamllint ' .. file end
    elseif ft == 'toml' then
        if fn.executable('taplo') == 1 then return 'taplo check ' .. file end
    elseif ft == 'markdown' then
        if fn.executable('markdownlint') == 1 then return 'markdownlint ' .. file end
    end
    return nil
end

function M.check()
    if fn.expand('%') == '' then
        notify('Current buffer has no file name; cannot check', vim.log.levels.WARN)
        return
    end
    if not save_if_needed() then return end

    local file = fn.shellescape(fn.expand('%:p'))
    local cmd = check_candidates(vim.bo.filetype, file)
    if not cmd then
        notify('No checker found for filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
        return
    end

    vim.system({ 'sh', '-c', cmd }, { cwd = file_dir(), text = true }, function(obj)
        vim.schedule(function()
            local output = vim.trim((obj.stdout or '') .. (obj.stderr or ''))
            if obj.code == 0 and output == '' then
                notify('Check passed, no issues found')
                return
            end

            local lines = vim.split(output, '\n', { trimempty = true })
            vim.fn.setqflist({}, ' ', { title = 'vimore check', lines = lines })
            if #lines > 0 then vim.cmd('copen') end
            notify('Issues found; see quickfix', vim.log.levels.WARN)
        end)
    end)
end

return M
