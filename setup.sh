#!/usr/bin/env bash
# NeoVimore 安装脚本
#   ./setup.sh        安装到 ~/.config/nvim（会询问作者/邮箱）
#   ./setup.sh --link 软链接仓库（作者/邮箱请用环境变量或编辑 lua/vimore/user.lua）
#   ./setup.sh --uninstall 卸载
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config/nvim"
MODE="copy"

usage() {
    cat <<EOF
用法: $0 [选项]

  (无参数)   复制配置到 ~/.config/nvim，并写入作者/邮箱
  --link     软链接 ~/.config/nvim 到本仓库（不修改仓库内容）
  --uninstall 删除本脚本安装的配置
  -h, --help 显示帮助

也可用环境变量 VIMORE_AUTHOR / VIMORE_EMAIL 非交互式提供作者信息。
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --link) MODE="link"; shift ;;
        --uninstall) MODE="uninstall"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知选项: $1" >&2; usage >&2; exit 2 ;;
    esac
done

backup_config() {
    if [[ -e "$CONFIG" || -L "$CONFIG" ]]; then
        local bak="${CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$CONFIG" "$bak"
        echo "已备份旧配置: $bak"
    fi
}

lua_quote() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\n\r'
}

write_user() {
    local dir="$1" author="$2" email="$3"
    mkdir -p "$dir/lua/vimore"
    cat > "$dir/lua/vimore/user.lua" <<EOF
-- 由 setup.sh 生成，可随时手动修改。
-- 也可用 VIMORE_AUTHOR / VIMORE_EMAIL 环境变量覆盖。
return {
    author = "$(lua_quote "$author")",
    email = "$(lua_quote "$email")",
}
EOF
}

read_user_info() {
    AUTHOR="${VIMORE_AUTHOR:-}"
    EMAIL="${VIMORE_EMAIL:-}"
    if [[ -t 0 ]]; then
        if [[ -z "$AUTHOR" ]]; then
            read -r -p "作者名字（留空则跳过）: " AUTHOR || true
        fi
        if [[ -z "$EMAIL" ]]; then
            read -r -p "邮箱（留空则跳过）: " EMAIL || true
        fi
    fi
}

verify() {
    if command -v nvim >/dev/null 2>&1; then
        if nvim --headless -c 'lua print("author=" .. vim.g.author .. " email=" .. vim.g.email)' -c 'qa!' </dev/null 2>&1 | tail -2; then
            echo "启动检查完成"
        else
            echo "警告：Neovim 启动报错，请用 nvim 查看 :messages" >&2
        fi
    else
        echo "未找到 nvim，跳过启动检查"
    fi
}

case "$MODE" in
    copy)
        read_user_info
        backup_config
        mkdir -p "$HOME/.config"
        mkdir -p "$CONFIG"
        cp -a "$ROOT/init.lua" "$ROOT/lua" "$ROOT/colors" "$ROOT/tutor" \
              "$ROOT/VimMaze.vim" "$ROOT/tests" "$ROOT/README.md" "$CONFIG/"
        if [[ -f "$ROOT/.stylua.toml" ]]; then cp "$ROOT/.stylua.toml" "$CONFIG/"; fi
        if [[ -f "$ROOT/.luarc.json" ]]; then cp "$ROOT/.luarc.json" "$CONFIG/"; fi
        write_user "$CONFIG" "$AUTHOR" "$EMAIL"
        echo "已安装到：$CONFIG"
        verify
        ;;

    link)
        if [[ -L "$CONFIG" && "$(readlink "$CONFIG")" == "$ROOT" ]]; then
            echo "$CONFIG 已经链接到 $ROOT"
        else
            backup_config
            ln -s "$ROOT" "$CONFIG"
            echo "已链接：$CONFIG -> $ROOT"
        fi
        echo "链接模式下不修改仓库里的 lua/vimore/user.lua；"
        echo "请设 VIMORE_AUTHOR / VIMORE_EMAIL，或编辑 $ROOT/lua/vimore/user.lua"
        verify
        ;;

    uninstall)
        if [[ -L "$CONFIG" && "$(readlink "$CONFIG")" == "$ROOT" ]]; then
            rm "$CONFIG"
        elif [[ -d "$CONFIG" && -f "$CONFIG/colors/vimore.lua" && -f "$CONFIG/lua/vimore/user.lua" ]]; then
            rm -rf "$CONFIG"
        else
            echo "$CONFIG 不是本脚本安装的，未删除" >&2
            exit 1
        fi
        echo "已删除 $CONFIG"
        ;;
esac
