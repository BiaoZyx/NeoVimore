# NeoVimore

> Less is more.

English quick reference. The Chinese [README](README.md) and the interactive
tutorials in `tutor/` are the canonical documentation.

NeoVimore is a modular Lua configuration for Neovim 0.11+. No plugin manager:
it uses Neovim built-ins only (built-in LSP, floating windows, terminal,
timers, vim.system). All runtime messages, menu labels and keymap descriptions
are in English.

## Install

```bash
# copy config and write author/email to lua/vimore/user.lua
./setup.sh

# symlink the repo instead (use VIMORE_AUTHOR / VIMORE_EMAIL env vars)
./setup.sh --link

./setup.sh --uninstall
# skip .bak files
./setup.sh --no-backup
```

Manual: `git clone ... ~/.config/nvim`. Run `:checkhealth vimore` afterwards.

## Key mappings

| Keys | Action |
|---|---|
| `<Space>` | Leader menu (floating which-key style) |
| `Ctrl-s` | Save (stays in Insert mode) |
| `Ctrl-h/j/k/l` | Move between windows |
| `Alt-Left/Right` | Previous / next tab |
| `Ctrl-x` (Visual) | Cut selection to system clipboard |
| `F2` | Toggle paste mode |
| `F3` / `F4` | File explorer / vertical file explorer |
| `F5` / `F6` | Run / debug current file in terminal |
| `F7` | Toggle line wrap (current buffer) |
| `F8` / `F10` | Async code check / format |
| `F9` | Basic indent (`gg=G`) |
| `gd` / `gD` / `K` | LSP definition / declaration / hover |
| `gr` / `gi` / `<C-k>` | LSP references / implementation / signature help |

Menu: `SPC w` Write, `SPC c` Maintain (check / keymaps / reload / tutorial /
checkhealth), `SPC b` Brackets, `SPC s` Sort / clean, `SPC t` Window,
`SPC z` View, `SPC g` Git, `SPC l` LSP, `SPC /` toggle comment, `SPC ?` tutorial.

Bracket handling:
- Empty `()` `[]` `{}`: Enter splits into three lines, cursor stays in Insert;
  no `<C-o>`, so LSP diagnostic labels do not flicker.
- At the end of a container: Enter moves the closing bracket to the next line.

Trailing whitespace is shown as a dim `·` and stripped on save (Markdown /
diff / gitcommit excluded). Terminal and nofile buffers never show it.

## Commands

- `:VimoreMenu` / `:VimoreKeys` — menu / keymap overview
- `:checkhealth vimore` — environment check (uses Neovim's standard health output)
- `:VimMaze` — maze game loaded from the repo root

## Options

Set before `require('vimore...')`:

```lua
vim.g.author = 'Your Name'
vim.g.email = 'you@example.com'
vim.g.vimore_autochdir = false
vim.g.vimore_strip_whitespace = true
vim.g.vimore_show_extra_whitespace = true
vim.g.vimore_menu_timeout = 3000
```

Treesitter highlighting is optional: run `:lua vim.treesitter.start()` if your
environment ships compatible parsers.

## License

GPL-3.0, see [LICENSE](LICENSE).
