-- ============================================================
-- :checkhealth vimore
-- ============================================================
local M = {}

local function exe(name) return vim.fn.executable(name) == 1 end

-- Neovim 自带的 vim.health.ok/warn/error 会硬编码 emoji；
-- 这里统一走 info，用彩色文字标记代替，颜色组在 colors/vimore.lua 定义。
local function report(mark, msg) vim.health.info('[' .. mark .. '] ' .. msg) end
local function ok(msg) report('OK', msg) end
local function warn(msg) report('WARN', msg) end
local function err(msg) report('ERROR', msg) end
local function inf(msg) report('INFO', msg) end

-- checkhealth 输出写完后，给文字标记上色（窗口局部 match，不污染别的 buffer）
local function colorize()
    vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == 'checkhealth' then
                local old = vim.w[win].vimore_health_match_ids
                if old then
                    for _, id in ipairs(old) do
                        pcall(vim.fn.matchdelete, id)
                    end
                end
                local ids = {}
                vim.api.nvim_win_call(win, function()
                    table.insert(ids, vim.fn.matchadd('VimoreHealthOk', '[OK]', 10))
                    table.insert(ids, vim.fn.matchadd('VimoreHealthWarn', '[WARN]', 10))
                    table.insert(ids, vim.fn.matchadd('VimoreHealthError', '[ERROR]', 10))
                    table.insert(ids, vim.fn.matchadd('VimoreHealthInfo', '[INFO]', 10))
                end)
                vim.w[win].vimore_health_match_ids = ids
            end
        end
    end)
end

function M.check()
    vim.health.start('vimore')

    -- ---------- 基础环境 ----------
    if vim.fn.has('nvim-0.11') == 1 then
        local v = vim.version()
        ok(('Neovim %d.%d.%d'):format(v.major, v.minor, v.patch))
    else
        err('需要 Neovim 0.11 或更高版本')
    end

    if vim.o.termguicolors then
        ok('termguicolors 已开启，使用主题的 hex 颜色')
    else
        ok('termguicolors 未开启，使用主题内置的 256 色回退')
    end

    if vim.g.colors_name == 'vimore' then
        ok('当前配色: vimore')
    else
        warn('当前配色不是 vimore，可执行 :colorscheme vimore')
    end

    inf('Leader: ' .. vim.fn.keytrans(vim.g.mapleader or ' '))

    -- ---------- 配置开关 ----------
    local toggles = {
        vimore_autochdir = vim.g.vimore_autochdir,
        vimore_strip_whitespace = vim.g.vimore_strip_whitespace,
        vimore_menu_timeout = vim.g.vimore_menu_timeout,
    }
    local parts = {}
    for k, v in pairs(toggles) do
        if v ~= nil then table.insert(parts, ('%s=%s'):format(k, tostring(v))) end
    end
    inf('配置开关: ' .. (#parts > 0 and table.concat(parts, ', ') or '全部使用默认值'))

    -- ---------- 界面能力 ----------
    if exe('wl-copy') or exe('xclip') or exe('xsel') or exe('pbcopy') then
        ok('系统剪切板工具可用（菜单里的 SPC y / p / P 依赖它）')
    else
        warn('未检测到 wl-copy / xclip / xsel / pbcopy，系统剪切板功能可能不可用')
    end

    if vim.fn.exists('g:loaded_netrwPlugin') == 1 then
        ok('netrw 已加载（F3 / F4 文件浏览器）')
    else
        warn('netrw 未加载；若使用精简版 Neovim，F3 / F4 可能不可用')
    end

    if vim.treesitter then
        ok('Treesitter 运行时可用；执行 :lua vim.treesitter.start() 可启用高亮')
    else
        inf('未检测到 Treesitter 运行时')
    end

    -- ---------- LSP ----------
    local loaded, lsp = pcall(require, 'vimore.lsp')
    if not loaded then
        err('无法加载 vimore.lsp')
    else
        local enabled = lsp.enabled or {}
        if #enabled > 0 then
            ok('已启用 LSP: ' .. table.concat(enabled, ', '))
        else
            warn('没有检测到任何 LSP 服务器；安装后会自动启用')
        end

        -- 列出已安装但没有被当前语言优先级选中的服务器
        local picked = lsp.picked or {}
        local unused = {}
        for name in pairs(lsp.servers or {}) do
            if not picked[name] and exe(lsp.servers[name].cmd[1]) then table.insert(unused, name) end
        end
        if #unused > 0 then
            table.sort(unused)
            inf('已安装但未启用的服务器: ' .. table.concat(unused, ', '))
        end

        if vim.lsp.completion then
            ok('内置 LSP 自动补全可用（vim.lsp.completion）')
        else
            inf('使用 omnifunc 补全（<C-x><C-o>）')
        end
    end

    -- ---------- 外部工具 ----------
    local formatters = {
        'stylua',
        'black',
        'ruff',
        'autopep8',
        'isort',
        'gofmt',
        'goimports',
        'rustfmt',
        'prettier',
        'eslint',
        'clang-format',
        'shfmt',
        'taplo',
        'mdformat',
        'xmllint',
        'sqlfluff',
        'rubocop',
        'php-cs-fixer',
        'zig',
    }
    local checkers = { 'luac', 'pylint', 'flake8', 'shellcheck', 'jq', 'yamllint' }

    local function report(title, list)
        local found = {}
        for _, name in ipairs(list) do
            if exe(name) then table.insert(found, name) end
        end
        if #found > 0 then
            ok(title .. ': ' .. table.concat(found, ', '))
        else
            inf(title .. ': 未检测到（相关功能会回退或跳过）')
        end
    end

    report('格式化工具', formatters)
    report('检查工具', checkers)

    -- ---------- 教程与游戏 ----------
    local config = vim.fn.stdpath('config')
    if vim.fn.filereadable(config .. '/tutor/Vimore.tutor.txt') == 1 then
        ok('交互式教程存在（:VimoreMenu 然后 ?）')
    else
        warn('找不到 tutor/Vimore.tutor.txt')
    end

    if vim.fn.filereadable(config .. '/VimMaze.vim') == 1 then
        ok('VimMaze 存在（:VimMaze）')
    else
        inf('未找到 VimMaze.vim，游戏不可用')
    end

    colorize()
end

return M
