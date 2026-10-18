-- ============================================================
-- 内置 LSP：按语言候选列表自动回退
-- 没装任何服务器则静默跳过，不报错、不弹提示
-- ============================================================
local M = {}

local fn = vim.fn
local api = vim.api

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
    tsserver = {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
    },
    denols = {
        cmd = { 'deno', 'lsp' },
        filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
        root_markers = { 'deno.json', 'deno.jsonc', 'mod.ts', '.git' },
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
}

-- ---------- 语言 -> 候选服务器（按优先级） ----------
-- 第一个可执行的服务器会被启用，后面的跳过
local lang_priority = {
    c = { 'clangd', 'ccls', 'cquery' },
    cpp = { 'clangd', 'ccls' },
    objc = { 'clangd' },
    objcpp = { 'clangd' },
    python = { 'basedpyright', 'pyright', 'ruff', 'pylsp' },
    go = { 'gopls' },
    gomod = { 'gopls' },
    gowork = { 'gopls' },
    rust = { 'rust_analyzer' },
    zig = { 'zls' },
    javascript = { 'denols', 'tsserver' },
    typescript = { 'denols', 'tsserver' },
    javascriptreact = { 'tsserver' },
    typescriptreact = { 'tsserver' },
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
local function has_exe(cmd)
    return fn.executable(cmd) == 1
end

-- 对每个语言，取第一个可用的服务器
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
    return picked
end

-- ---------- LspAttach 键位映射 ----------
local function on_attach(args)
    local buf = args.buf
    local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = buf, silent = true, desc = 'LSP: ' .. desc })
    end
    map('gd', vim.lsp.buf.definition, '跳转定义')
    map('gD', vim.lsp.buf.declaration, '跳转声明')
    map('K', vim.lsp.buf.hover, '悬停文档')
    map('gr', vim.lsp.buf.references, '查找引用')
    map('gi', vim.lsp.buf.implementation, '跳转实现')
    map('<Leader>ld', vim.lsp.buf.definition, '跳转定义')
    map('<Leader>lh', vim.lsp.buf.hover, '悬停文档')
    map('<Leader>lr', vim.lsp.buf.rename, '重命名符号')
    map('<Leader>la', vim.lsp.buf.code_action, '代码操作')
    map('<Leader>le', vim.diagnostic.open_float, '行诊断')
    map('<Leader>lq', vim.diagnostic.setqflist, '诊断到 quickfix')

    -- LSP 接管补全（completion.lua 里检测到 LSP 会跳过覆盖 omnifunc）
    vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
end

-- ---------- setup ----------
local function setup()
    local picked = pick_servers()
    local enabled = {}
    for name in pairs(picked) do
        vim.lsp.config(name, servers[name])
        table.insert(enabled, name)
    end
    if #enabled > 0 then
        vim.lsp.enable(enabled)
    end

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('VimoreLsp', { clear = true }),
        callback = on_attach,
    })

    vim.diagnostic.config({
        virtual_text = { prefix = '■', spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = 'rounded', source = true },
    })
end

setup()

return M
