-- ============================================================
-- :checkhealth vimore
-- ============================================================
local M = {}

local function exe(name) return vim.fn.executable(name) == 1 end

function M.check()
    vim.health.start('vimore')

    -- ---------- 基础环境 ----------
    if vim.fn.has('nvim-0.11') == 1 then
        local v = vim.version()
        vim.health.ok(('Neovim %d.%d.%d'):format(v.major, v.minor, v.patch))
    else
        vim.health.error('需要 Neovim 0.11 或更高版本')
    end

    if vim.o.termguicolors then
        vim.health.ok('termguicolors 已开启，使用主题的 hex 颜色')
    else
        vim.health.ok('termguicolors 未开启，使用主题内置的 256 色回退')
    end

    if vim.g.colors_name == 'vimore' then
        vim.health.ok('当前配色: vimore')
    else
        vim.health.warn('当前配色不是 vimore，可执行 :colorscheme vimore')
    end

    vim.health.info('Leader: ' .. vim.fn.keytrans(vim.g.mapleader or ' '))

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
    vim.health.info('配置开关: ' .. (#parts > 0 and table.concat(parts, ', ') or '全部使用默认值'))

    -- ---------- 界面能力 ----------
    if exe('wl-copy') or exe('xclip') or exe('xsel') or exe('pbcopy') then
        vim.health.ok('系统剪切板工具可用（菜单里的 SPC y / p / P 依赖它）')
    else
        vim.health.warn('未检测到 wl-copy / xclip / xsel / pbcopy，系统剪切板功能可能不可用')
    end

    if vim.fn.exists('g:loaded_netrwPlugin') == 1 then
        vim.health.ok('netrw 已加载（F3 / F4 文件浏览器）')
    else
        vim.health.warn('netrw 未加载；若使用精简版 Neovim，F3 / F4 可能不可用')
    end

    if vim.treesitter then
        vim.health.ok('Treesitter 运行时可用；执行 :lua vim.treesitter.start() 可启用高亮')
    else
        vim.health.info('未检测到 Treesitter 运行时')
    end

    -- ---------- LSP ----------
    local ok, lsp = pcall(require, 'vimore.lsp')
    if not ok then
        vim.health.error('无法加载 vimore.lsp')
    else
        local enabled = lsp.enabled or {}
        if #enabled > 0 then
            vim.health.ok('已启用 LSP: ' .. table.concat(enabled, ', '))
        else
            vim.health.warn('没有检测到任何 LSP 服务器；安装后会自动启用')
        end

        -- 列出已安装但没有被当前语言优先级选中的服务器
        local picked = lsp.picked or {}
        local unused = {}
        for name in pairs(lsp.servers or {}) do
            if not picked[name] and exe(lsp.servers[name].cmd[1]) then table.insert(unused, name) end
        end
        if #unused > 0 then
            table.sort(unused)
            vim.health.info('已安装但未启用的服务器: ' .. table.concat(unused, ', '))
        end

        if vim.lsp.completion then
            vim.health.ok('内置 LSP 自动补全可用（vim.lsp.completion）')
        else
            vim.health.info('使用 omnifunc 补全（<C-x><C-o>）')
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
            vim.health.ok(title .. ': ' .. table.concat(found, ', '))
        else
            vim.health.info(title .. ': 未检测到（相关功能会回退或跳过）')
        end
    end

    report('格式化工具', formatters)
    report('检查工具', checkers)

    -- ---------- 教程与游戏 ----------
    local config = vim.fn.stdpath('config')
    if vim.fn.filereadable(config .. '/tutor/Vimore.tutor.txt') == 1 then
        vim.health.ok('交互式教程存在（:VimoreMenu 然后 ?）')
    else
        vim.health.warn('找不到 tutor/Vimore.tutor.txt')
    end

    if vim.fn.filereadable(config .. '/VimMaze.vim') == 1 then
        vim.health.ok('VimMaze 存在（:VimMaze）')
    else
        vim.health.info('未找到 VimMaze.vim，游戏不可用')
    end
end

return M
