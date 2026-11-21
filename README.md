# NeoVimore

> Less is more.

[English](README.en.md) | 中文

一个 **Neovim 原生增强基础配置**：不依赖插件管理器，只靠 `init.lua` 和
Neovim 内置能力（内置 LSP、浮动窗口、terminal、timers），把 Neovim 配成
一套顺手、现代、开箱即用的编辑器。

前身是 [Vimore](https://github.com/BiaoZyx/Vimore)（纯 Vimscript 的 Vim
配置）。NeoVimore 把它完整移植为模块化 Lua，并用 Neovim 0.11+ 内置的
`vim.lsp` 替代了原版可选的 yegappan/lsp 插件。

---

## 这是什么

NeoVimore 是一份按模块组织的 Lua 配置，目标是：

- **零插件依赖**：不装插件管理器，不拉任何插件仓库
- **原生增强**：只用 Neovim 自带能力（内置 LSP、浮动窗口、自动命令、
  `terminal`、`timers`、`vim.system`）
- **现代化手感**：which-key 风格菜单、智能括号、异步格式化/检查
- **开箱即用**：拷到 `~/.config/nvim` 就能用，不需要编译

适合：

- 想在服务器 / 容器 / 陌生机器上快速获得一套顺手的 Neovim
- 不想被插件生态绑架，但又觉得原版 Neovim 太素
- 喜欢用 Lua 折腾配置的人

需要 **Neovim 0.11+**（用到了 `vim.lsp.config` / `vim.lsp.enable`）。
推荐使用支持 true color 的终端。

---

## 安装

仓库根目录的 `setup.sh` 会复制配置并询问作者/邮箱：

```bash
./setup.sh            # 安装到 ~/.config/nvim，提示输入名字和邮箱
./setup.sh --link     # 软链接仓库（不改仓库内容，作者信息用环境变量）
./setup.sh --uninstall
./setup.sh --no-backup  # 覆盖时不生成 .bak
./setup.sh -y         # 跳过询问（作者信息用环境变量提供）
./setup.sh --version  # 显示版本
./setup.sh --help     # 查看全部选项
```

也可以手动安装：

```bash
git clone https://github.com/BiaoZyx/NeoVimore.git ~/.config/nvim
# 或者软链接
ln -s /path/to/NeoVimore ~/.config/nvim
```

作者/邮箱（用于文件头）存在 `lua/vimore/user.lua`，由 `setup.sh` 生成：

```lua
return {
    author = 'Your Name',
    email = 'you@example.com',
}
```

留空时新文件头不会写这两行；也可以用 `VIMORE_AUTHOR` / `VIMORE_EMAIL`
环境变量临时覆盖。

启动后建议先跑一遍：

```vim
:checkhealth vimore
```

它会检查版本、配色、剪切板、LSP、外部格式化/检查工具和教程文件。
使用 Neovim 自带的 `vim.health` 标准输出（状态图标由 health 框架生成）。

---

## 目录结构

```
NeoVimore/
├── init.lua                 -- 入口：版本检查 + 按序加载模块
├── colors/
│   └── vimore.lua           -- 配色（:colorscheme vimore）
├── lua/vimore/
│   ├── options.lua          -- 基础、编码、缩进、搜索、编辑行为
│   ├── ui.lua               -- 行号、光标形状、边界线
│   ├── statusline.lua       -- 自定义状态栏
│   ├── tabline.lua          -- 自定义标签栏
│   ├── pairs.lua            -- 括号/引号智能补全
│   ├── comment.lua          -- 快速注释
│   ├── terminal.lua         -- 终端集成与运行
│   ├── completion.lua       -- 补全、括号内回车拆分
│   ├── folds.lua            -- 代码折叠
│   ├── whitespace.lua       -- 行尾空格显示与清理
│   ├── keymaps.lua          -- 普通快捷键、F 键
│   ├── runner.lua           -- 异步格式化、检查、调试
│   ├── netrw.lua            -- File explorer（netrw）
│   ├── header.lua           -- 文件头自动生成
│   ├── autocmds.lua         -- 自动命令
│   ├── lsp.lua              -- 内置 LSP（零插件）
│   ├── menu.lua             -- Leader 浮动菜单 + Keymap overview
│   ├── game.lua             -- VimMaze 按需加载器
│   ├── neovide.lua          -- NeoVide GUI 专属设置
│   └── health.lua           -- :checkhealth vimore
├── VimMaze.vim              -- 迷宫探索小游戏（:VimMaze，按需加载）
├── tutor/
│   ├── Vimore.tutor.txt     -- 本配置的 15 章交互式教程
│   └── vim.tutor.txt        -- 原版 Vim 的 11 章基础教程
├── tests/                   -- 无依赖 smoke test
├── README.md
└── LICENSE
```

约 3000 行 Lua（含注释和配色）。没有 `plugin/` 自动加载目录，启动时只
加载上面这些模块；`VimMaze.vim` 在第一次 `:VimMaze` 时才 source。

---

## 主要特性

### Leader 菜单

单独按一下 `<Space>` 立即弹出 which-key 风格浮动菜单：

- 顶层列出所有可用键，`<名字>` 表示子菜单
- 进入子菜单后标题显示当前路径，如 `Leader c - Maintain`
- 3 秒无操作自动收起；`Esc`、再按一次空格、或按菜单里没有的键也会关闭
- 菜单里没有的键关闭菜单后会正常交给编辑器，不会吞掉 `j` / `k`
- 普通模式和可视模式都能用；可视模式下选区不会消失

`<Space>` 是**唯一入口**：新增命令只改 `lua/vimore/menu.lua` 里的
`menu` 表，不会再散落成一堆 `<Leader>xx` 映射。

常用项：

| 键 | 作用 |
|---|---|
| `SPC w` | 写入子菜单（保存、保存退出、清行尾空格、Word count） |
| `SPC q` / `SPC Q` | 退出 / Quit all |
| `SPC y` / `SPC p` / `SPC P` | 系统剪切板复制 / 粘贴 / 前粘贴 |
| `SPC /` | 注释 / 取消注释（可视模式整块） |
| `SPC b d <Brackets>` / `SPC b c <Brackets>` / `SPC b a <Brackets>` | 只删包裹符号 / 换包裹符号 / 给选区加括号 |
| `SPC t` | 终端、标签页、File explorer |
| `SPC l` | LSP 操作 |
| `SPC F` | 轻量文件搜索（无结果时回退到 netrw） |
| `SPC z` | 折叠 |
| `SPC s` | 排序、去重、删空行 |
| `SPC g` | Git |
| `SPC c` | 检查、Keymap overview、重载配置、checkhealth、教程 |
| `SPC ?` | 打开交互式教程 |

`:VimoreKeys` 或 `SPC c k` 可以查看当前所有全局快捷键。

### 界面

- 相对行号 + 插入模式自动切绝对行号
- 自定义状态栏：模式指示器、文件名、文件类型、编码、行列、时间
- 自定义标签栏：标签名截断、修改标记、当前标签高亮
- 行尾空格显示成淡灰 `·` + 保存时自动清理（Markdown、diff、gitcommit 除外）
- `colorcolumn=120` 边界线
- true color 配色（`colors/vimore.lua`），可随时 `:colorscheme vimore` 切回
- 光标形状随模式切换
- 复制时短暂高亮 yank 区域

### 编辑

- 智能括号 / 引号补全：`(` `[` `{` `"` 自动配对，`<` 只在 HTML/XML 配对
- 智能退格：成对删除 `()` `[]` `{}` `""` `''`
- 在 `()` `[]` `{}` 中间回车，自动拆成三行并保持缩进（尊重 `noexpandtab`）
- 在 `[]` / `{}` / `()` 等容器**末尾**回车，把右括号挪到下一行，内容单独占一行
- 两种拆分都留在插入模式，不经过 `<C-o>`，有 LSP 时诊断标签不会闪一下
- 快速注释：`SPC /`，支持 Python / C / HTML / CSS / Lua 等
- 普通模式保留标准 Vim 的 `<` / `>` / `<C-t>` / `j` / `k` 行为；
  只有可视模式的 `<` / `>` 缩进后会保持选区，方便连续缩进

### 搜索

- 增量搜索、智能大小写、高亮结果
- `SPC h h` 取消高亮

### 终端

- `SPC t t` Terminal (bottom)
- `SPC t v` Terminal (right)
- `SPC t r` 在最新终端运行当前文件
- `SPC t k` 切换 / 关闭终端
- 终端里 `Esc Esc` 回普通模式，`Ctrl-C` 强制透传
- `Ctrl-Shift-c` / `Ctrl-Shift-v` 复制 / 粘贴系统剪切板

### 运行 / 格式化 / 检查

- `<F5>` Run current file（Python / Go / C / C++ / JavaScript / Java / Shell / Lua / Rust）
- `<F6>` 调试当前文件（Python pdb、C/C++ gdb、Go dlv）
- `<F8>` Check code
- `<F9>` 基础格式化（`gg=G`）
- `<F10>` 自动格式化（优先调用外部工具）

格式化和检查都是**异步**的，不会卡住编辑器。支持的工具包括：

- 格式化：`stylua`、`black` / `ruff` / `autopep8` / `isort`、`gofmt` /
  `goimports`、`rustfmt`、`prettier`、`eslint --fix`、`clang-format`、
  `shfmt`、`taplo`、`mdformat`、`xmllint`、`sqlfluff`、`rubocop`、
  `php-cs-fixer`、`zig fmt` 等
- 检查：`ruff` / `pylint` / `flake8`、`eslint`、`go vet`、`cargo check`、
  `luac -p`、`shellcheck`、`gcc -fsyntax-only`、`jq`、`yamllint` 等

装了哪个用哪个；一个都没有时自动回退到 `gg=G` 或直接提示。

### 文件头自动生成

新建 `.py` / `.go` / `.sh` / `.bash` / `.c` / `.cc` / `.cpp` / `.h` /
`.hpp` / `.java` / `.js` / `.ts` / `.rs` / `.lua` 时自动插入文件头：

- Python：shebang、三引号 Doxygen 头（Python 3 默认 UTF-8，不写编码行）
- Go：注释头 + 按目录推导的 `package` 名（只有 `main` 包才生成 `func main`）
- C / C++：注释头（不强行塞 `include` 或 `main`）
- Java：注释头 + 类骨架
- Shell：shebang 用 `#!/bin/sh`（POSIX 标准）；JS / TS / Rust / Lua：对应风格的注释头

作者和邮箱取自 `vim.g.author` / `vim.g.email`，留空则不写。

### 内置 LSP

用 Neovim 0.11+ 内置的 `vim.lsp.config` / `vim.lsp.enable`，零插件获得
补全、跳转定义、悬停文档等 IDE 能力：

- `gd` Go to definition / `gD` Go to declaration / `K` Hover docs
- `gr` 查找引用 / `gi` 跳转实现 / `<C-k>` Signature help
- 附加后自动开启 `vim.lsp.completion`（输入时弹补全），补全列表用 `fuzzy` 匹配
- `<C-x><C-o>` 手动弹出补全；`<Tab>` / `<S-Tab>` 翻候选，Snippet 占位符也用它跳
- 光标停在某符号上时，同文件引用会高亮（LspReference* 配色已内置）
- Inlay Hints 默认开启（插入模式临时隐藏），`<Leader>li` 切换；Code Lens 用 `<Leader>lr` 运行
- 诊断带 `E/W/I/H` 标记，状态栏显示 `E:n W:n`；`]d` / `[d` 跳下一个 / 上一个
- C 语言的指针 `*` 等操作符统一用蓝色（Operator / @operator）

内置 51 个服务器定义，**装了哪个启用哪个**，没装的静默跳过。常用安装方式：

| 语言 | 服务器 | 安装示例 |
|---|---|---|
| C / C++ | clangd / ccls / cquery | `sudo apt install clangd` |
| Python | basedpyright / pyright / ruff / pylsp | `npm i -g pyright` 或 `pip install ruff` |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| Rust | rust-analyzer | `rustup component add rust-analyzer` |
| Zig | zls | 见 zls 文档 |
| JS / TS | vtsls / tsgo / tsserver / denols | `npm i -g typescript-language-server` |
| Svelte / Vue / Astro | svelteserver / vue-language-server / astro-ls | 见各自文档 |
| Tailwind / Emmet | tailwindcss-language-server / emmet-ls | `npm i -g @tailwindcss/language-server emmet-ls` |
| GraphQL / Prisma | graphql-lsp / prisma-language-server | `npm i -g graphql-language-service-cli prisma` |
| PHP | intelephense / phpactor | `npm i -g intelephense` |
| C# | csharp-language-server / omnisharp | 见各自文档 |
| Dart / Kotlin / Solidity | dartls / kotlin-language-server / solidity-ls | 见各自文档 |
| LaTeX | texlab | `cargo install texlab` |
| Protobuf / Helm | bufls / protols / helm-ls | 见各自文档 |
| Shell | bash-language-server | `npm i -g bash-language-server` |
| Lua | lua-language-server | `sudo apt install lua-language-server` |
| Java | jdtls | 见 jdtls 文档 |
| Clojure | clojure-lsp | 见 clojure-lsp 文档 |
| JSON / HTML / CSS | vscode-json / html / css-language-server | `npm i -g vscode-langservers-extracted` |
| YAML | yaml-language-server | `npm i -g yaml-language-server` |
| Vim | vim-language-server | `npm i -g vim-language-server` |
| Markdown | marksman | 见 marksman 文档 |
| TOML | taplo | `cargo install taplo-cli --features lsp` |
| CMake | cmake-language-server | `pip install cmake-language-server` |
| SQL | sql-language-server | `npm i -g sql-language-server` |
| Dockerfile | docker-langserver | `npm i -g dockerfile-language-server-nodejs` |
| Terraform | terraform-ls | 见 terraform-ls 文档 |
| Nix | nil | `nix profile install nixpkgs#nil` |

JavaScript / TypeScript 依次尝试 `vtsls` → `tsgo` → `tsserver`；只有检测到 `deno.json` /
`deno.jsonc` / `deno.lock` 时才让 `denols` 接管，不会靠 `.git` 抢普通项目。

装完确认在 `$PATH` 里：

```bash
which clangd pyright-langserver gopls lua-language-server
```

### VimMaze 小游戏

仓库根目录的 `VimMaze.vim` 是一个纯 Vimscript 的迷宫探索小游戏，不依赖
任何插件，也不会拖慢启动（第一次玩才加载）：

```vim
:VimMaze
```

进入游戏后底部会列出操作键，按 `?` 可以随时看帮助。`s` 保存、`L` 读取，
存档目录是 `~/.vimmaze`，和原版 Vimore 共用；`q` 退出。

### 其他

- `:VimoreKeys`：Keymap overview
- `:VimoreMenu`：用命令打开 Leader 菜单（方便测试/演示）
- `:checkhealth vimore`：环境自检
- `SPC c v`：Reload config
- `SPC c e`：编辑 `$MYVIMRC`
- 文件在外部被修改时自动 `checktime`
- 打开文件恢复上次光标位置
- 文档类文件（Markdown / text / org / gitcommit 等）自动软换行，其他文件不折行
- `F7` 手动切换当前 buffer 的 wrap（之后该 buffer 不再被自动规则覆盖）

---

## 快捷键速查

### 全局

| 键 | 作用 |
|---|---|
| `<Space>` | Leader 菜单 |
| `Ctrl-s` | 保存（普通 / 插入模式，插入模式保存后仍留在插入） |
| `Ctrl-h/j/k/l` | 切到左 / 下 / 上 / 右窗口 |
| `Alt-Left` / `Alt-Right` | 上一个 / 下一个标签页 |
| `Ctrl-x`（可视） | 剪切选区到系统剪切板 |
| `<` / `>`（可视） | 反缩进 / 缩进，保持选区 |
| `F2` | 粘贴模式开关 |
| `F3` / `F4` | 文件浏览器 / 垂直文件浏览器 |
| `F5` / `F6` | 运行 / 调试 |
| `F7` | 切换 wrap |
| `F8` / `F9` / `F10` | 检查 / 基础缩进 / 自动格式化 |

### 终端模式

| 键 | 作用 |
|---|---|
| `Esc Esc` | 回普通模式 |
| `Ctrl-c` | 透传 Ctrl-C |
| `Ctrl-w h/j/k/l` | 切窗口 |
| `Ctrl-Shift-c/v` | 复制当前行 / 粘贴系统剪切板 |

---

## 教程

```bash
nvim -c 'e ~/.config/nvim/tutor/Vimore.tutor.txt'
# 或在编辑器里：SPC ?
```

基础 Vim 教程（不依赖本配置）：

```bash
vim --clean ~/.config/nvim/tutor/vim.tutor.txt
```

---

## 测试

无第三方依赖：

```bash
bash tests/run.sh
```

会用隔离的 XDG 目录启动 `nvim --headless`，加载配置并检查配色、
Leader 菜单（普通 / 可视）、`<C-s>`、命令、补全拆分、文件头等关
键行为。

---

## 可调开关

都在 `init.lua` 里加载模块之前设置：

```lua
-- 文件头的作者信息
vim.g.author = 'Your Name'
vim.g.email = 'you@example.com'

-- 进入 buffer 时把工作目录切到文件所在目录（默认关闭）
vim.g.vimore_autochdir = true

-- 保存时不再自动清理行尾空格（默认开启清理）
vim.g.vimore_strip_whitespace = false

-- 不显示行尾空格高亮（终端 / nofile 缓冲本来就不显示）
vim.g.vimore_show_extra_whitespace = false

-- Leader 菜单无操作自动收起的时间，单位毫秒（默认 3000）
vim.g.vimore_menu_timeout = 5000
```

注释符也可以在 `init.lua` 里覆盖：

```lua
vim.g.comment_map = vim.tbl_extend('force', vim.g.comment_map or {}, {
    mylang = '// ',
})
```

---

## 常见问题

**颜色发灰、像 16 色终端**

配置只在终端声明真彩（`COLORTERM=truecolor` / `24bit`，或 `TERM` 含
`truecolor` / `direct`）时开启 `termguicolors`；否则自动用主题内置的
256 色回退。想强制真彩，可在 `init.lua` 里设 `vim.opt.termguicolors = true`。
`:checkhealth vimore` 会显示当前走的是哪条路径。

**按空格没反应，或菜单要等一下才出现**

`<Space>` 必须是 `mapleader`，而且不能再有更长的 `<Leader>xx` 映射；
两者都由本配置保证。如果是自己加的映射，先删掉或改成非 Leader 前缀。
`:VimoreMenu` 可以直接从命令打开菜单，方便排查。

**`SPC y` / `SPC p` 不能复制粘贴到系统剪切板**

需要 `wl-copy`（Wayland）、`xclip` / `xsel`（X11）或 `pbcopy`（macOS）。
`:checkhealth vimore` 会告诉你缺哪个。

**F3 / F4 打不开文件浏览器**

有些精简版 Neovim 去掉了 netrw；`:checkhealth vimore` 会提示。可以直接
用 `:Explore`，或安装完整版 Neovim。

**LSP 没启动**

服务器必须在 `$PATH` 里，文件名还要和命令一致。用 `:checkhealth vimore`
看哪些已安装、哪些已启用，或用 `:lua =vim.lsp.get_clients()` 看当前
buffer 的客户端。服务器只在对应语言的文件里启动。

**格式化 / 检查没反应**

这些功能依赖外部工具；装了哪个用哪个，一个都没有时格式化会回退到
`gg=G`，检查会直接提示。`:checkhealth vimore` 会列出检测到的工具。

---

## 与原版 Vimore 的差异

| 项目 | Vimore (Vim) | NeoVimore (Neovim) |
|---|---|---|
| 语言 | 单文件 Vimscript | 模块化 Lua |
| 配置入口 | `~/.vimrc` | `~/.config/nvim/init.lua` |
| Leader 菜单 | `popup_create` | `nvim_open_win` 浮动窗口 |
| 光标形状 | `t_SI` / `t_EI` 转义序列 | `guicursor` + 配色 |
| LSP | 可选 yegappan/lsp（Vim9script） | 内置 `vim.lsp`（零插件） |
| 撤销/备份目录 | `~/.vim/undodir` 等 | `stdpath('state')` |
| 粘贴开关 | `pastetoggle`（Neovim 已移除） | `<F2>` 映射切换 |
| 终端 Ctrl-C | `term_sendkeys`（Neovim 已移除） | `chansend` |
| 颜色 | gui / 256 色 / 8 色三套 | 真彩优先，自动 256 色回退 |
| 迷宫游戏 | 手动 source | `:VimMaze` 按需加载 |

---

## License

MIT，见 [LICENSE](LICENSE)。
