-- ============================================================
-- NeoVide GUI配置
-- ============================================================
if not vim.g.neovide then
    return {}
end

-- ---------- 交互优化 ----------
-- 可以用鼠标直接拖选底部命令行消息区域里的文字
vim.g.neovide_message_area_drag_selection = true

-- ---------- 字体 ----------
-- 主字体 + 备选字体，h 后是字号
vim.o.guifont = "JetBrainsMono_Nerd_Font_Mono,Noto_Color_Emoji,Noto_Sans_Mono_CJK_SC:h10"
-- 行间距（负数会更紧凑）
vim.opt.linespace = 2
-- 下划线宽度跟随字体大小自动调整
vim.g.neovide_underline_automatic_scaling = true

-- ---------- 缩放 ----------
-- 全局缩放因子，1.0 为默认
vim.g.neovide_scale_factor = 1.0

-- ---------- 透明度 ----------
-- 整体不透明度（含标题栏/状态栏）
vim.g.neovide_opacity = 0.95
-- 编辑区不透明度，可与上者不同
vim.g.neovide_normal_opacity = 0.95

-- ---------- 动画 ----------
-- 光标移动动画时长（秒），0 为关闭
vim.g.neovide_cursor_animation_length = 0.12
-- 短距离移动的动画时长，让微调更跟手
vim.g.neovide_cursor_short_animation_length = 0.05
-- 滚动动画时长
vim.g.neovide_scroll_animation_length = 0.15
-- 位置/窗口切换动画时长
vim.g.neovide_position_animation_length = 0.1
-- 输入时隐藏鼠标
vim.g.neovide_hide_mouse_when_typing = true

-- ---------- 光标特效 ----------
-- 拖尾移动速度
vim.g.neovide_cursor_animation_length = 0.04
-- 拖尾长度，0 为关闭
vim.g.neovide_cursor_trail_size = 1.0
-- 抗锯齿，让光标边缘更平滑
vim.g.neovide_cursor_antialiasing = true
-- 插入模式也播放光标动画（如果觉得花哨可以设 false）
vim.g.neovide_cursor_animate_in_insert_mode = true
-- 光标粒子特效，可选 "railgun", "pixiedust", "torpedo", "dissolve" 等
vim.g.neovide_cursor_vfx_mode = "railgun"
vim.g.neovide_cursor_vfx_particle_density = 13.0  -- 粒子密度
vim.g.neovide_cursor_vfx_particle_speed = 10.0    -- 粒子速度
vim.g.neovide_cursor_vfx_particle_lifetime = 0.5  -- 粒子存活时间（秒）
-- 光标在命令行也做动画
vim.g.neovide_cursor_animate_command_line = true
-- 平滑闪烁
-- vim.g.neovide_cursor_smooth_blink = true

-- ---------- 窗口行为 ----------
-- 记住上次窗口尺寸
vim.g.neovide_remember_window_size = true
-- 未保存退出时确认
vim.g.neovide_confirm_quit = true
-- 空闲时也强制重绘 (动画卡顿时可开启，略耗电)
-- vim.g.neovide_no_idle = false

-- ---------- 背景模糊 (Linux/macOS 有效) ----------
-- 浮动窗口的模糊强度，2.0 是常用值
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0
-- 浮动窗口阴影
vim.g.neovide_floating_shadow = true

-- ---------- 进度条 (LSP 进度) ----------
vim.g.neovide_progress_bar_enabled = true
vim.g.neovide_progress_bar_height = 4.0
vim.g.neovide_progress_bar_animation_speed = 200.0
vim.g.neovide_progress_bar_hide_delay = 0.3

-- ---------- 性能调节 ----------
-- 聚焦时 60fps，失焦时降到 5fps 省电
vim.g.neovide_refresh_rate = 60
vim.g.neovide_refresh_rate_idle = 5

-- ---------- 输入法自动切换 ----------
local ime_group = vim.api.nvim_create_augroup("neovide_ime", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    group = ime_group,
    callback = function()
        vim.g.neovide_input_ime = true
    end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = ime_group,
    callback = function()
        vim.g.neovide_input_ime = false
    end,
})
