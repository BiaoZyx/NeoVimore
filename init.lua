-- ============================================================
-- NeoVimore
-- 版本: 0.21
-- ============================================================
--  _   ___
-- | | / (_)_ _  ___  _______
-- | |/ / /  ' \/ _ \/ __/ -_)
-- |___/_/_/_/_/\___/_/  \__/
--                   Less is more.
-- ============================================================
-- Neovim 原生增强基础配置：零插件依赖，纯 Lua + 内置能力
-- 需要 Neovim 0.11+（vim.lsp.config / vim.lsp.enable）
-- ============================================================

if vim.fn.has('nvim-0.11') == 0 then
    vim.notify('NeoVimore 需要 Neovim 0.11 或更高版本', vim.log.levels.ERROR)
    return
end

-- 文件头自动生成用的作者信息。setup.sh 会写 lua/vimore/user.lua；
-- 也可以手动改那里，或者设 VIMORE_AUTHOR / VIMORE_EMAIL 环境变量覆盖。
local ok, user = pcall(require, 'vimore.user')
if not (ok and type(user) == 'table') then user = {} end
vim.g.author = vim.g.author or user.author or os.getenv('VIMORE_AUTHOR') or ''
vim.g.email = vim.g.email or user.email or os.getenv('VIMORE_EMAIL') or ''

-- Lua 模块缓存，能明显缩短重复启动时间
if vim.loader then vim.loader.enable() end

-- 按依赖顺序加载模块。options 必须最先（含 mapleader）。
require('vimore.options') -- 基础选项、编码、搜索、编辑行为
vim.cmd.colorscheme('vimore') -- 配色（colors/vimore.lua）
require('vimore.ui') -- 行号、光标、边界线
require('vimore.neovide') -- NeoVide GUI 专属设置（非 GUI 自动跳过）
require('vimore.statusline') -- 状态栏
require('vimore.tabline') -- 标签栏
require('vimore.pairs') -- 括号/引号智能补全
require('vimore.comment') -- 快速注释
require('vimore.terminal') -- 终端集成
require('vimore.completion') -- 补全
require('vimore.folds') -- 代码折叠
require('vimore.whitespace') -- 行尾空格显示与清理
require('vimore.keymaps') -- 普通快捷键、F 键
require('vimore.runner') -- 运行、调试、格式化、检查
require('vimore.netrw') -- 文件浏览器（netrw）
require('vimore.header') -- 文件头自动生成
require('vimore.autocmds') -- 自动命令
require('vimore.lsp') -- 内置 LSP（零插件）
require('vimore.menu') -- Leader 提示菜单（最后加载，作为统一入口）
require('vimore.game') -- VimMaze 按需加载
