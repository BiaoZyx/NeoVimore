-- ============================================================
-- 3. 状态栏
-- ============================================================
local M = {}

-- 模式指示器（根据当前模式返回高亮组 + 文字）
function M.mode()
    local m = vim.api.nvim_get_mode().mode
    local map = {
        n = '%#ModeNormal# [-]%*',
        i = '%#ModeInsert# [I]%*',
        v = '%#ModeVisual# [v]%*',
        V = '%#ModeVLine# [V]%*',
        ['\22'] = '%#ModeVBlock# [B]%*',
        R = '%#ModeReplace# [R]%*',
        c = '%#ModeCmdline# [C]%*',
        t = '%#ModeTerminal# [T]%*',
    }
    return map[m] or ''
end

function M.diagnostics()
    local diags = vim.diagnostic.get(0)
    if #diags == 0 then return '' end
    local errors, warns = 0, 0
    for _, d in ipairs(diags) do
        if d.severity == vim.diagnostic.severity.ERROR then
            errors = errors + 1
        elseif d.severity == vim.diagnostic.severity.WARN then
            warns = warns + 1
        end
    end
    if errors == 0 and warns == 0 then return '' end
    return string.format(' E:%d W:%d', errors, warns)
end

local function setup()
    local sl = ''
    sl = sl .. '%{%v:lua.require("vimore.statusline").mode()%} ' -- 模式指示器
    sl = sl .. '%f%m%r%h%w%*' -- 文件名、修改标志、只读等
    sl = sl .. '%=' -- 右对齐
    sl = sl .. '%2* [%Y]%*' -- 文件类型
    sl = sl .. [[%3* [%{&ff}] [%{&fenc!=''?&fenc:&enc}]%*]] -- 格式 & 编码
    sl = sl .. '%4* [%l,%v] [%p%%]%*' -- 行、列、百分比
    sl = sl .. '%4*%{v:lua.require("vimore.statusline").diagnostics()}%*' -- 诊断计数
    sl = sl .. "%5* %{strftime('%H:%M')}%* " -- 当前时间
    vim.o.statusline = sl
end

setup()

return M
