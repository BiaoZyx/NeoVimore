# NeoVimore

> Less is more.

一个 **Neovim 原生增强基础配置**。不依赖任何插件管理器，只靠 `init.lua` 本身和
Neovim 内置能力（内置 LSP、浮动窗口、terminal、timers），把 Neovim 配成一个
顺手、现代、「开箱即用」的编辑器。

前身是 [Vimore](https://github.com/BiaoZyx/Vimore)（纯 Vimscript 的 Vim 配置），
本项目将其完整移植为模块化 Lua 配置，并用 Neovim 内置 LSP 替代了原版可选的
yegappan/lsp 插件（Vim9script 实现，Neovim 无法运行）。

---

## What is NeoVimore?

NeoVimore is a modular Lua config for Neovim that turns stock Neovim into a
modern, out-of-the-box editor — without any plugin manager, LSP plugin, or
external dependency. It provides a which-key style floating menu, smart
bracket handling, terminal integration, Git shortcuts, and built-in LSP
support, all in ~1500 lines of Lua across a dozen small modules.

## 这是什么

NeoVimore 是一份按模块组织的 Lua 配置，目标是：

- **零插件依赖**：不装任何插件管理器，不拉任何 GitHub 仓库
- **原生增强**：只用 Neovim 自带的能力（内置 LSP、浮动窗口、自动命令、
  `terminal`、`timers`）
- **现代化手感**：借鉴 Helix / which-key 的交互，但保持 Vim 的键位逻辑
- **开箱即用**：拷到 `~/.config/nvim` 就能用，不需要额外编译或配置

适合：

- 想在服务器 / 容器 / 陌生机器上快速获得一套顺手的 Neovim
- 不想被插件生态绑架，但又觉得原版 Neovim 太「素」
- 喜欢用 Lua 折腾配置的人

需要 **Neovim 0.11+**（用到了 `vim.lsp.config` / `vim.lsp.enable` API）。

---

## 安装

```bash
git clone <this-repo> ~/.config/nvim
# 或者软链接
ln -s /path/to/NeoVimore ~/.config/nvim
```

首次启动前，编辑 `init.lua` 顶部的作者信息（用于文件头自动生成）：

```lua
vim.g.author = 'Your Name'
vim.g.email  = 'you@example.com'
```

---

## 目录结构

```
NeoVimore/
├── init.lua                 -- 入口：作者信息 + 按序加载模块
├── lua/vimore/
│   ├── options.lua          -- 基础、编码、缩进、搜索、编辑行为
│   ├── ui.lua               -- 界面显示、高亮、边界线
│   ├── statusline.lua       -- 自定义状态栏
│   ├── tabline.lua          -- 自定义标签栏
│   ├── pairs.lua            -- 括号/引号智能补全
│   ├── comment.lua          -- 快速注释
│   ├── terminal.lua         -- 终端集成
│   ├── completion.lua       -- 补全
│   ├── folds.lua            -- 代码折叠
│   ├── whitespace.lua       -- 行尾空格显示与清理
│   ├── keymaps.lua          -- 剪贴板、普通快捷键、F 键
│   ├── runner.lua           -- 运行、调试、格式化、检查
│   ├── netrw.lua            -- 文件浏览器（netrw）
│   ├── header.lua           -- 文件头自动生成
│   ├── autocmds.lua         -- 自动命令
│   ├── lsp.lua              -- 内置 LSP（零插件）
│   └── menu.lua             -- Leader 浮动提示菜单
├── plugin/VimMaze.vim       -- 迷宫探索小游戏（:VimMaze）
├── tutor/                   -- 教程文件
└── README.md
```

---

## 主要特性

### 界面

- 相对行号 + 插入模式自动切绝对行号
- 自定义状态栏：模式指示器、文件名、文件类型、编码、行列、时间
- 自定义标签栏：标签名截断、修改标记、当前标签高亮
- 行尾空格高亮 + 保存时自动清理
- `colorcolumn=120` 边界线
- true color 高亮（`termguicolors`），光标形状随模式切换（`guicursor`）

### 编辑

- 智能括号 / 引号补全：`(` `[` `"` `<` `{` 自动配对
- 智能退格：成对删除 `()` `[]` `{}` `""` `''`
- 括号操作：`<Leader>b`
- 单按 `<` / `>` 缩进当前行，可视模式缩进选区并保持选中
- 快速注释：`<Leader>/`，支持 Python / C / HTML / CSS / Lua 等

### 搜索

- 增量搜索、智能大小写、高亮结果
- `<Leader>hh` 取消高亮

### 终端

- `<Leader>tt` 底部终端
- `<Leader>tv` 右侧终端
- `<Leader>tr` 在最新终端运行当前文件
- `<Leader>tk` 切换 / 关闭终端
- 终端里 `Esc Esc` 回普通模式，`Ctrl-C` 强制透传

### 运行 / 格式化 / 检查

- `<F5>` 运行当前文件
- `<F6>` 调试当前文件
- `<F8>` 代码检查
- `<F9>` 基础格式化（`gg=G`）
- `<F10>` 自动格式化（优先用 black / gofmt / prettier / clang-format）

### Leader 提示菜单

按 `<Space>` 单独停住，弹出 which-key 风格的**浮动窗口**菜单：

- 顶层显示所有可用键，子菜单用 `<名字>` 标出
- 进入子菜单后，标题栏显示如 `Leader c - 维护`
- 支持「具体映射优先，没有映射才进菜单」（`timeoutlen=300`）

### 文件头自动生成

新建 `.py` / `.go` / `.sh` / `.c` / `.cpp` / `.java` / `.js` 时，
自动插入作者、邮箱、日期、描述等文件头。

### 内置 LSP

用 Neovim 0.11+ 内置的 `vim.lsp.config` / `vim.lsp.enable`，
**零插件**获得补全、跳转定义、悬停文档等 IDE 能力：

- `gd` 跳转定义 / `gD` 跳转声明 / `K` 悬停文档
- `gr` 查找引用 / `gi` 跳转实现
- `<Leader>ld/lh/lr/la/le/lq`：定义 / 悬停 / 重命名 / 代码操作 / 诊断 / quickfix
- LSP 附加后自动接管 `omnifunc`（`<C-x><C-o>` 触发）

支持三种语言服务器，**装了哪个启用哪个**，没装的静默跳过：

| 语言 | 服务器 | 安装 |
|---|---|---|
| C / C++ | clangd | `sudo apt install clangd` 或 `sudo pacman -S clang` |
| Python | pyright | `npm i -g pyright` |
| Shell | bash-language-server | `npm i -g bash-language-server` |

装完确认在 `$PATH` 里：

```bash
which clangd pyright-langserver bash-language-server
```

---

## 与原版 Vimore 的差异

| 项目 | Vimore (Vim) | NeoVimore (Neovim) |
|---|---|---|
| 语言 | 单文件 Vimscript | 模块化 Lua |
| 配置入口 | `~/.vimrc` | `~/.config/nvim/init.lua` |
| Leader 菜单 | `popup_create` | `nvim_open_win` 浮动窗口 |
| 光标形状 | `t_SI`/`t_EI` 转义序列 | `guicursor` |
| LSP | 可选 yegappan/lsp（Vim9script） | 内置 `vim.lsp`（零插件） |
| 撤销/备份目录 | `~/.vim/undodir` 等 | `stdpath('state')` |
| 粘贴开关 | `pastetoggle`（Neovim 已移除） | `<F2>` 映射切换 |
| 终端 Ctrl-C | `term_sendkeys`（Neovim 已移除） | `chansend` |
| 颜色 | gui/256色/8色三套 | 统一 true color |
| 迷宫游戏 | 手动 source | `plugin/VimMaze.vim` 自动加载 |

---

## 教程

```bash
nvim -c 'e ~/.config/nvim/tutor/Vimore.tutor.txt'
```

## License

MIT，见 [LICENSE](LICENSE)。
