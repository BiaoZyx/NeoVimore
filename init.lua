-- ============================================================
-- NeoVimore
-- 作者: BiaoZyx
-- 邮箱: BiaoZyx@outlook.com
-- 版本: 0.2
-- ============================================================
--  _   ___
-- | | / (_)_ _  ___  _______
-- | |/ / /  ' \/ _ \/ __/ -_)
-- |___/_/_/_/_/\___/_/  \__/
--                   Less is more.
-- ============================================================
-- Neovim 原生增强基础配置：零插件依赖，纯 Lua + 内置能力
-- ============================================================

-- 文件头自动生成用的作者信息
vim.g.author = 'Change it in ~/.config/nvim/init.lua'
vim.g.email = 'Change it in ~/.config/nvim/init.lua'

-- 按依赖顺序加载模块（options 必须最先，含 mapleader）
require('vimore.options')     -- 1/4/5/6/7: 基础、编码、缩进、搜索、编辑行为
require('vimore.ui')          -- 2/15: 界面显示、高亮、边界线
require('vimore.statusline')  -- 3: 状态栏
require('vimore.tabline')     -- 22: 标签栏
require('vimore.pairs')       -- 8: 括号/引号智能补全
require('vimore.comment')     -- 10: 快速注释
require('vimore.terminal')    -- 11: 终端集成
require('vimore.completion')  -- 12: 补全
require('vimore.folds')       -- 13: 代码折叠
require('vimore.whitespace')  -- 14: 行尾空格显示与清理
require('vimore.keymaps')     -- 9/16/17: 剪贴板、普通快捷键、F 键
require('vimore.runner')      -- 18: 运行、调试、格式化、检查
require('vimore.netrw')       -- 19: 文件浏览器
require('vimore.header')      -- 20: 文件头自动生成
require('vimore.autocmds')    -- 21: 自动命令
require('vimore.lsp')         -- 内置 LSP（替代 yegappan/lsp）
require('vimore.menu')        -- 23: Leader 提示菜单（浮动窗口）
