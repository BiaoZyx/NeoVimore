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
        vim.health.error('Neovim 0.11+ is required')
    end

    if vim.o.termguicolors then
        vim.health.ok('termguicolors enabled; using hex colors from the theme')
    else
        vim.health.ok('termguicolors disabled; using built-in 256-color fallback')
    end

    if vim.g.colors_name == 'vimore' then
        vim.health.ok('Colorscheme: vimore')
    else
        vim.health.warn('Colorscheme is not vimore; run :colorscheme vimore')
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
    vim.health.info('Options: ' .. (#parts > 0 and table.concat(parts, ', ') or 'all defaults'))

    -- ---------- 界面能力 ----------
    if exe('wl-copy') or exe('xclip') or exe('xsel') or exe('pbcopy') then
        vim.health.ok('System clipboard tool available (used by SPC y / p / P)')
    else
        vim.health.warn('No wl-copy / xclip / xsel / pbcopy found; system clipboard may not work')
    end

    if vim.fn.exists('g:loaded_netrwPlugin') == 1 then
        vim.health.ok('netrw loaded (F3 / F4 file explorer)')
    else
        vim.health.warn('netrw not loaded; F3 / F4 may be unavailable in minimal Neovim')
    end

    if vim.treesitter then
        vim.health.ok('Treesitter runtime available; run :lua vim.treesitter.start() to enable highlighting')
    else
        vim.health.info('No Treesitter runtime detected')
    end

    -- ---------- LSP ----------
    local loaded, lsp = pcall(require, 'vimore.lsp')
    if not loaded then
        vim.health.error('Failed to load vimore.lsp')
    else
        local enabled = lsp.enabled or {}
        if #enabled > 0 then
            vim.health.ok('Enabled LSP: ' .. table.concat(enabled, ', '))
        else
            vim.health.warn('No LSP servers detected; install one to enable automatically')
        end

        -- 列出已安装但没有被当前语言优先级选中的服务器
        local picked = lsp.picked or {}
        local unused = {}
        for name in pairs(lsp.servers or {}) do
            if not picked[name] and exe(lsp.servers[name].cmd[1]) then table.insert(unused, name) end
        end
        if #unused > 0 then
            table.sort(unused)
            vim.health.info('Installed but unused servers: ' .. table.concat(unused, ', '))
        end

        if vim.lsp.completion then
            vim.health.ok('Built-in LSP completion available (vim.lsp.completion)')
        else
            vim.health.info('Using omnifunc completion (<C-x><C-o>)')
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
            vim.health.info(title .. ': none detected (feature falls back or is skipped)')
        end
    end

    report('Formatters', formatters)
    report('Checkers', checkers)

    -- ---------- 教程与游戏 ----------
    local config = vim.fn.stdpath('config')
    if vim.fn.filereadable(config .. '/tutor/Vimore.tutor.txt') == 1 then
        vim.health.ok('Interactive tutorial available (:VimoreMenu then ?)')
    else
        vim.health.warn('tutor/Vimore.tutor.txt not found')
    end

    if vim.fn.filereadable(config .. '/VimMaze.vim') == 1 then
        vim.health.ok('VimMaze available (:VimMaze)')
    else
        vim.health.info('VimMaze.vim not found; game unavailable')
    end
end

return M
