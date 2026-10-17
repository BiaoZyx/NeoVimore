-- ============================================================
-- 内置 LSP（替代 Vimore 的可选 yegappan/lsp 插件）
-- 使用 Neovim 0.11+ 的 vim.lsp.config / vim.lsp.enable，零插件依赖
-- ============================================================
local M = {}

-- 语言服务器定义（没有安装对应服务器时自动跳过，不报错）
local servers = {
    clangd = {
        cmd = { 'clangd', '--background-index' },
        filetypes = { 'c', 'cpp' },
        root_markers = { 'compile_commands.json', '.clangd', '.git' },
    },
    pyright = {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
    },
    bashls = {
        cmd = { 'bash-language-server', 'start' },
        filetypes = { 'sh', 'bash' },
        root_markers = { '.git' },
    },
}

local function setup()
    local enabled = {}
    for name, config in pairs(servers) do
        if vim.fn.executable(config.cmd[1]) == 1 then
            vim.lsp.config(name, config)
            table.insert(enabled, name)
        end
    end
    if #enabled > 0 then
        vim.lsp.enable(enabled)
    end

    -- LSP 附加后的缓冲区设置
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('VimoreLsp', { clear = true }),
        callback = function(args)
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

            -- LSP 接管补全
            vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
        end,
    })

    -- 诊断显示
    vim.diagnostic.config({
        virtual_text = { prefix = '■' },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = 'rounded' },
    })
end

setup()

return M
