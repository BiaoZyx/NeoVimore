-- ============================================================
-- 内置 LSP：按语言候选列表自动回退
-- 没装任何服务器则静默跳过，不报错、不弹提示
-- ============================================================
local M = {}

local fn = vim.fn
local api = vim.api

-- JS/TS 服务器统一：Deno 项目让位给 denols
local function js_root(bufnr)
    if vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' }) then return nil end
    return vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' })
end

-- ---------- 服务器定义 ----------
-- cmd: 启动命令（第一个元素用来检测可执行文件）
-- filetypes: 服务的文件类型
-- root_markers: 识别项目根的标志文件
-- settings: 可选，服务器特定设置
local servers = {
    -- ===== C / C++ =====
    clangd = {
        cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=iwyu' },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
        root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
    },
    ccls = {
        cmd = { 'ccls' },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
        root_markers = { '.ccls', 'compile_commands.json', '.git' },
    },
    cquery = {
        cmd = {
            'cquery',
            '--init={"cacheDirectory":"/tmp/cquery"}', -- 关键：必须指定缓存目录
        },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
        root_markers = { 'compile_commands.json', '.git' },
    },

    -- ===== Python =====
    basedpyright = {
        cmd = { 'basedpyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
        settings = { basedpyright = { analysis = { typeCheckingMode = 'basic' } } },
    },
    pyright = {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
    },
    ruff = {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', '.git' },
    },
    pylsp = {
        cmd = { 'pylsp' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
    },

    -- ===== Go =====
    gopls = {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = { gopls = { usePlaceholders = true } },
    },

    -- ===== Rust =====
    rust_analyzer = {
        cmd = { 'rust-analyzer' },
        filetypes = { 'rust' },
        root_markers = { 'Cargo.toml', '.git' },
    },

    -- ===== Zig =====
    zls = {
        cmd = { 'zls' },
        filetypes = { 'zig' },
        root_markers = { 'build.zig', '.git' },
    },

    -- ===== JavaScript / TypeScript =====
    vtsls = {
        cmd = { 'vtsls', '--stdio' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        root_dir = js_root,
    },
    tsgo = {
        cmd = { 'tsgo', '--lsp', '--stdio' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        root_dir = js_root,
    },
    tsserver = {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        root_dir = js_root,
    },
    denols = {
        cmd = { 'deno', 'lsp' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'deno.json', 'deno.jsonc', 'deno.lock' },
        -- 只有真正的 Deno 项目才启动，绝不靠 .git 抢普通 JS/TS 项目
        root_dir = function(bufnr) return vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' }) end,
        workspace_required = true,
    },

    -- ===== Shell =====
    bashls = {
        cmd = { 'bash-language-server', 'start' },
        filetypes = { 'sh', 'bash' },
        root_markers = { '.git' },
    },

    -- ===== Lua =====
    lua_ls = {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
        settings = { Lua = { runtime = { version = 'LuaJIT' } } },
    },

    -- ===== Java =====
    jdtls = {
        cmd = { 'jdtls' },
        filetypes = { 'java' },
        root_markers = { 'pom.xml', 'build.gradle', 'settings.gradle', '.git' },
    },

    -- ===== Clojure =====
    clojure_lsp = {
        cmd = { 'clojure-lsp' },
        filetypes = { 'clojure', 'clojurescript' },
        root_markers = { 'deps.edn', 'project.clj', 'shadow-cljs.edn', '.git' },
    },

    -- ===== 配置 / 标记语言 =====
    jsonls = {
        cmd = { 'vscode-json-language-server', '--stdio' },
        filetypes = { 'json', 'jsonc' },
        root_markers = { '.git' },
    },
    yamlls = {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml' },
        root_markers = { '.git' },
    },
    html = {
        cmd = { 'vscode-html-language-server', '--stdio' },
        filetypes = { 'html' },
        root_markers = { '.git' },
    },
    cssls = {
        cmd = { 'vscode-css-language-server', '--stdio' },
        filetypes = { 'css', 'scss', 'less' },
        root_markers = { '.git' },
    },
    vimls = {
        cmd = { 'vim-language-server', '--stdio' },
        filetypes = { 'vim' },
        root_markers = { '.git' },
    },
    marksman = {
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown' },
        root_markers = { '.marksman.toml', '.git' },
    },
    taplo = {
        cmd = { 'taplo', 'lsp', 'stdio' },
        filetypes = { 'toml' },
        root_markers = { '.git' },
    },
    cmake = {
        cmd = { 'cmake-language-server' },
        filetypes = { 'cmake' },
        root_markers = { 'CMakeLists.txt', '.git' },
    },
    sqlls = {
        cmd = { 'sql-language-server', 'up', '--method', 'stdio' },
        filetypes = { 'sql' },
        root_markers = { '.git' },
    },
    dockerls = {
        cmd = { 'docker-langserver', '--stdio' },
        filetypes = { 'dockerfile' },
        root_markers = { 'Dockerfile', '.git' },
    },
    terraformls = {
        cmd = { 'terraform-ls', 'serve' },
        filetypes = { 'terraform' },
        root_markers = { '.terraform', '.git' },
    },
    nil_ls = {
        cmd = { 'nil' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', 'default.nix', '.git' },
    },

    -- ===== 更多前端 / 框架 =====
    svelte = {
        cmd = { 'svelteserver', '--stdio' },
        filetypes = { 'svelte' },
        root_markers = { 'package.json', 'svelte.config.js', '.git' },
    },
    vue_ls = {
        cmd = { 'vue-language-server', '--stdio' },
        filetypes = { 'vue' },
        root_markers = { 'package.json', 'vue.config.js', '.git' },
    },
    astro = {
        cmd = { 'astro-ls', '--stdio' },
        filetypes = { 'astro' },
        root_markers = { 'astro.config.mjs', 'package.json', '.git' },
    },
    tailwindcss = {
        cmd = { 'tailwindcss-language-server', '--stdio' },
        filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact', 'php', 'vue', 'svelte' },
        root_markers = { 'tailwind.config.js', 'tailwind.config.ts', 'package.json', '.git' },
    },
    emmet_ls = {
        cmd = { 'emmet-ls', '--stdio' },
        filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'package.json', '.git' },
    },
    prismals = {
        cmd = { 'prisma-language-server', '--stdio' },
        filetypes = { 'prisma' },
        root_markers = { 'schema.prisma', 'package.json', '.git' },
    },
    graphql = {
        cmd = { 'graphql-lsp', 'server', '-m', 'stream' },
        filetypes = { 'graphql', 'gql' },
        root_markers = { '.graphqlrc', 'graphql.config.yml', 'package.json', '.git' },
    },

    -- ===== 更多后端语言 =====
    jedi_language_server = {
        cmd = { 'jedi-language-server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', '.git' },
    },
    intelephense = {
        cmd = { 'intelephense', '--stdio' },
        filetypes = { 'php' },
        root_markers = { 'composer.json', '.git' },
    },
    phpactor = {
        cmd = { 'phpactor', 'language-server' },
        filetypes = { 'php' },
        root_markers = { 'composer.json', '.git' },
    },
    csharp_ls = {
        cmd = { 'csharp-language-server' },
        filetypes = { 'cs' },
        root_markers = { '*.sln', '*.csproj', '.git' },
    },
    omnisharp = {
        cmd = { 'omnisharp', '-lsp' },
        filetypes = { 'cs' },
        root_markers = { '*.sln', '*.csproj', '.git' },
    },
    dartls = {
        cmd = { 'dart', 'language-server', '--protocol=lsp' },
        filetypes = { 'dart' },
        root_markers = { 'pubspec.yaml', '.git' },
    },
    kotlin_language_server = {
        cmd = { 'kotlin-language-server' },
        filetypes = { 'kotlin' },
        root_markers = { 'settings.gradle', 'settings.gradle.kts', 'pom.xml', '.git' },
    },
    solidity_ls = {
        cmd = { 'solidity-language-server', '--stdio' },
        filetypes = { 'solidity' },
        root_markers = { 'foundry.toml', 'hardhat.config.js', '.git' },
    },
    texlab = {
        cmd = { 'texlab' },
        filetypes = { 'tex', 'latex', 'bib' },
        root_markers = { '.latexmkrc', 'latexmkrc', '.git' },
    },
    ltex = {
        cmd = { 'ltex-ls' },
        filetypes = { 'markdown', 'text', 'tex', 'latex' },
        root_markers = { '.git' },
    },
    bufls = {
        cmd = { 'bufls', 'serve' },
        filetypes = { 'proto' },
        root_markers = { 'buf.yaml', 'buf.work.yaml', '.git' },
    },
    protols = {
        cmd = { 'protols' },
        filetypes = { 'proto' },
        root_markers = { 'buf.yaml', '*.proto', '.git' },
    },
    helm_ls = {
        cmd = { 'helm-ls' },
        filetypes = { 'helm' },
        root_markers = { 'Chart.yaml', '.git' },
    },
    docker_compose_language_service = {
        cmd = { 'docker-compose-language-service', '--stdio' },
        filetypes = { 'yaml' },
        root_markers = { 'docker-compose.yml', 'docker-compose.yaml', 'compose.yml', 'compose.yaml', '.git' },
    },
}

-- ---------- 语言 -> 候选服务器（按优先级） ----------
-- 第一个可执行的服务器会被启用，后面的跳过
local lang_priority = {
    c = { 'clangd', 'ccls', 'cquery' },
    cpp = { 'clangd', 'ccls' },
    objc = { 'clangd' },
    objcpp = { 'clangd' },
    python = { 'basedpyright', 'pyright', 'ruff', 'pylsp', 'jedi_language_server' },
    go = { 'gopls' },
    gomod = { 'gopls' },
    gowork = { 'gopls' },
    rust = { 'rust_analyzer' },
    zig = { 'zls' },
    javascript = { 'vtsls', 'tsgo', 'tsserver' },
    typescript = { 'vtsls', 'tsgo', 'tsserver' },
    javascriptreact = { 'vtsls', 'tsgo', 'tsserver' },
    typescriptreact = { 'vtsls', 'tsgo', 'tsserver' },
    svelte = { 'svelte' },
    vue = { 'vue_ls' },
    astro = { 'astro' },
    prisma = { 'prismals' },
    graphql = { 'graphql' },
    gql = { 'graphql' },
    php = { 'intelephense', 'phpactor' },
    cs = { 'csharp_ls', 'omnisharp' },
    dart = { 'dartls' },
    kotlin = { 'kotlin_language_server' },
    solidity = { 'solidity_ls' },
    tex = { 'texlab' },
    latex = { 'texlab' },
    bib = { 'texlab' },
    proto = { 'bufls', 'protols' },
    helm = { 'helm_ls' },
    sh = { 'bashls' },
    bash = { 'bashls' },
    lua = { 'lua_ls' },
    java = { 'jdtls' },
    clojure = { 'clojure_lsp' },
    clojurescript = { 'clojure_lsp' },
    json = { 'jsonls' },
    jsonc = { 'jsonls' },
    yaml = { 'yamlls' },
    html = { 'html' },
    css = { 'cssls' },
    scss = { 'cssls' },
    less = { 'cssls' },
    vim = { 'vimls' },
    markdown = { 'marksman' },
    toml = { 'taplo' },
    cmake = { 'cmake' },
    sql = { 'sqlls' },
    dockerfile = { 'dockerls' },
    terraform = { 'terraformls' },
    nix = { 'nil_ls' },
}

-- ---------- 工具函数 ----------
local function has_exe(cmd) return fn.executable(cmd) == 1 end

-- 对每个语言，取第一个可用的服务器
-- denols 比较特殊：它不参与优先级竞争，只有当 deno 存在时额外启用，
-- 再由 root_dir 决定是否真的在 Deno 项目里启动。
local extra_servers = { 'denols', 'tailwindcss', 'emmet_ls', 'ltex', 'docker_compose_language_service' }

local function pick_servers()
    local picked = {}
    for _, candidates in pairs(lang_priority) do
        for _, name in ipairs(candidates) do
            local cfg = servers[name]
            if cfg and has_exe(cfg.cmd[1]) then
                picked[name] = true
                break
            end
        end
    end
    for _, name in ipairs(extra_servers) do
        local cfg = servers[name]
        if cfg and has_exe(cfg.cmd[1]) then picked[name] = true end
    end
    return picked
end

-- ---------- LspAttach 键位映射 ----------
local function on_attach(args)
    local buf = args.buf
    -- Neovim 通过 args.data.client_id 传客户端 ID（旧代码里常见 args.client_id）
    local client_id = (args.data and args.data.client_id) or args.client_id
    local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = buf, silent = true, desc = 'LSP: ' .. desc })
    end

    -- 这里刻意不放 <Leader>l* 映射：Leader 是统一菜单入口，
    -- 任何更长的 Leader 映射都会让菜单等待 timeoutlen 才出现。
    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gD', vim.lsp.buf.declaration, 'Go to declaration')
    map('K', vim.lsp.buf.hover, 'Hover docs')
    map('gr', vim.lsp.buf.references, 'Find references')
    map('gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('<C-k>', vim.lsp.buf.signature_help, 'Signature help')
    map('<Leader>lr', vim.lsp.codelens.run, 'Run code lens')
    -- 用户开关单独记在 buffer 上；插入模式只是临时隐藏，不改用户意图
    vim.b[buf].vimore_inlay_on = true
    map('<Leader>li', function()
        if not vim.lsp.inlay_hint then return end
        local want = not vim.b[buf].vimore_inlay_on
        vim.b[buf].vimore_inlay_on = want
        local in_insert = vim.api.nvim_get_mode().mode == 'i'
        vim.lsp.inlay_hint.enable(want and not in_insert, { bufnr = buf })
    end, 'Toggle inlay hints')

    if vim.lsp.inlay_hint then
        vim.api.nvim_create_autocmd('InsertEnter', {
            group = hl_group,
            buffer = buf,
            callback = function() vim.lsp.inlay_hint.enable(false, { bufnr = buf }) end,
        })
        vim.api.nvim_create_autocmd('InsertLeave', {
            group = hl_group,
            buffer = buf,
            callback = function()
                if vim.b[buf].vimore_inlay_on then vim.lsp.inlay_hint.enable(true, { bufnr = buf }) end
            end,
        })
    end

    -- 光标下的符号高亮，离开就清掉（配色里已有 LspReference*）
    local hl_group = api.nvim_create_augroup('VimoreLspRef', { clear = false })
    api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = hl_group,
        buffer = buf,
        callback = function() vim.lsp.buf.document_highlight() end,
    })
    api.nvim_create_autocmd('CursorMoved', {
        group = hl_group,
        buffer = buf,
        callback = function() vim.lsp.buf.clear_references() end,
    })

    -- LSP 接管补全（completion.lua 里检测到 LSP 会跳过覆盖 omnifunc）
    vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    if client_id and vim.lsp.completion then
        -- 每个客户端都要单独开启；重复调用对同一个客户端是幂等的
        vim.lsp.completion.enable(true, client_id, buf, { autotrigger = true })
    end
end

-- ---------- setup ----------
local function setup()
    local picked = pick_servers()
    local enabled = {}
    for name in pairs(picked) do
        vim.lsp.config(name, servers[name])
        table.insert(enabled, name)
    end
    table.sort(enabled)
    if #enabled > 0 then vim.lsp.enable(enabled) end

    M.picked = picked
    M.enabled = enabled

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('VimoreLsp', { clear = true }),
        callback = on_attach,
    })
    api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost' }, {
        group = api.nvim_create_augroup('VimoreCodelens', { clear = true }),
        callback = function() vim.lsp.codelens.enable(true, { bufnr = 0 }) end,
    })

    vim.diagnostic.config({
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = 'E',
                [vim.diagnostic.severity.WARN] = 'W',
                [vim.diagnostic.severity.INFO] = 'I',
                [vim.diagnostic.severity.HINT] = 'H',
            },
        },
        virtual_text = { prefix = '■', spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = 'rounded', source = true },
    })

    -- 插入模式隐藏虚拟文本诊断，退出后恢复
    local virtual_text = vim.diagnostic.config().virtual_text
    local diag_group = api.nvim_create_augroup('VimoreDiagInsert', { clear = true })
    api.nvim_create_autocmd('InsertEnter', {
        group = diag_group,
        callback = function() vim.diagnostic.config({ virtual_text = false }) end,
    })
    api.nvim_create_autocmd('InsertLeave', {
        group = diag_group,
        callback = function() vim.diagnostic.config({ virtual_text = virtual_text }) end,
    })
end

setup()

M.servers = servers
M.lang_priority = lang_priority

return M
