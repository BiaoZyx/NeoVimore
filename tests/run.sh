#!/usr/bin/env bash
# 无依赖 smoke test：用隔离的 XDG 目录加载本仓库配置
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config" "$tmp/state" "$tmp/data"
ln -s "$root" "$tmp/config/nvim"

export XDG_CONFIG_HOME="$tmp/config"
export XDG_STATE_HOME="$tmp/state"
export XDG_DATA_HOME="$tmp/data"

cd "$root"
nvim --headless -c 'luafile tests/smoke.lua'
