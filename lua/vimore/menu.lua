-- ============================================================
-- 23. Leader 提示菜单（浮动窗口实现，仿 which-key / Helix）
-- ============================================================
local M = {}

local api = vim.api

-- ---------- 依赖函数 ----------
-- Leader w c：统计字数
local function word_count()
    local keys = vim.api.nvim_replace_termcodes('g<C-g>', true, false, true)
    api.nvim_feedkeys(keys, 'n', false)
end

-- Leader b a：给可视选区加括号
function M.add_pair(pair)
    local map = { ['('] = ')', ['['] = ']', ['{'] = '}', ['"'] = '"', ["'"] = "'" }
    if map[pair] == nil then
        vim.api.nvim_echo({ { '不支持的括号: ' .. pair, 'WarningMsg' } }, false, {})
        return
    end
    local left = pair
    local right = map[left]

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    if start_pos[2] == 0 or end_pos[2] == 0 then
        vim.api.nvim_echo({ { '没有可视选区', 'WarningMsg' } }, false, {})
        return
    end

    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]

    if start_line == end_line then
        local line = vim.fn.getline(start_line)
        local prefix = start_col > 1 and line:sub(1, start_col - 1) or ''
        local new_line = prefix .. left .. line:sub(start_col, end_col) .. right .. line:sub(end_col + 1)
        vim.fn.setline(start_line, new_line)
    else
        local first = vim.fn.getline(start_line)
        local last = vim.fn.getline(end_line)
        local prefix = start_col > 1 and first:sub(1, start_col - 1) or ''
        vim.fn.setline(start_line, prefix .. left .. first:sub(start_col))
        vim.fn.setline(end_line, last:sub(1, end_col) .. right .. last:sub(end_col + 1))
    end
end

-- ---------- 菜单主体 ----------
-- 叶子节点: { 描述, 动作（函数或 ':' 命令字符串） }
-- 子菜单: 带 name 字段的表
local opt = require('vimore.options')
local ws = require('vimore.whitespace')
local comment = require('vimore.comment')
local term = require('vimore.terminal')
local runner = require('vimore.runner')

local menu = {
    w = {
        name = '写入',
        w = { '保存', opt.save_and_clear },
        s = { '清理行尾空格', ws.strip_manual },
        c = { '统计字数', word_count },
    },
    q = { '退出', ':silent! quit<CR>' },
    W = { '全部保存', ':silent! wall<CR>' },
    Q = { '全部退出', ':silent! qall<CR>' },
    h = {
        name = '显示',
        h = { '取消搜索高亮', ':nohlsearch<CR>' },
        x = { '十六进制模式', ':%!xxd<CR>' },
        X = { '退出十六进制', ':%!xxd -r<CR>' },
    },
    f = { '格式化代码', runner.format },
    c = {
        name = '维护',
        c = { '代码检查', runner.check },
        v = { '重新加载配置', function()
            vim.fn.timer_start(0, function()
                vim.cmd.source(vim.fn.stdpath('config') .. '/init.lua')
            end)
        end },
        e = { '编辑配置', ':e $MYVIMRC<CR>' },
    },
    ['/'] = { '注释/取消注释', comment.toggle_smart },
    b = {
        name = '括号',
        d = {
            name = '删除指定括号对及其内容',
            ['('] = { '圆括号', ':execute "normal! da" . nr2char(40)<CR>' },
            ['['] = { '方括号', ':execute "normal! da" . nr2char(91)<CR>' },
            ['{'] = { '花括号', ':execute "normal! da" . nr2char(123)<CR>' },
            ['"'] = { '双引号', ':execute "normal! da" . nr2char(34)<CR>' },
            ["'"] = { '单引号', ':execute "normal! da" . nr2char(39)<CR>' },
        },
        a = {
            name = '在可视选区外添加指定括号',
            ['('] = { '圆括号', function() M.add_pair('(') end },
            ['['] = { '方括号', function() M.add_pair('[') end },
            ['{'] = { '花括号', function() M.add_pair('{') end },
            ['"'] = { '双引号', function() M.add_pair('"') end },
            ["'"] = { '单引号', function() M.add_pair("'") end },
        },
    },
    r = { '查看寄存器', ':reg<CR>' },
    z = {
        name = '视图',
        z = { '全部折叠', ':normal! zM<CR>' },
        a = { '切换折叠', ':normal! za<CR>' },
        Z = { '全部展开', ':normal! zR<CR>' },
    },
    y = { '复制到系统剪切板', ':normal! "+yy<CR>' },
    p = { '从系统剪切板粘贴', ':normal! "+p<CR>' },
    P = { '从系统剪切板粘贴(前)', ':normal! "+P<CR>' },
    s = {
        name = '整理',
        d = { '删除空行', ':silent! g/^\\s*$/d<CR>' },
        s = { '排序选中行', ':sort<CR>' },
        u = { '去重排序', ':sort u<CR>' },
        n = { '数字排序', ':sort n<CR>' },
    },
    g = {
        name = 'Git',
        s = { 'git status', ':!git status<CR>' },
        d = { 'git diff', ':!git diff<CR>' },
        l = { 'git log', ':!git log --oneline --graph<CR>' },
        a = { 'git add', ':!git add %<CR>' },
        c = { 'git commit', ':!git commit -m "<C-r>=input(\'Commit: \')<CR>"<CR>' },
        p = { 'git push', ':!git push<CR>' },
        P = { 'git pull', ':!git pull<CR>' },
    },
    t = {
        name = '窗口',
        t = { '底部终端', function() term.open('horizontal') end },
        v = { '右侧终端', function() term.open('vertical') end },
        r = { '运行当前文件', term.run_in_latest },
        k = { '切换/关闭终端', term.toggle },
        n = { '新建标签', ':tabnew<CR>' },
        e = { '新标签编辑当前', ':tabedit %<CR>' },
        c = { '关闭标签', ':tabclose<CR>' },
        o = { '保留当前标签', ':tabonly<CR>' },
        M = { '左移标签', ':tabmove -1<CR>' },
        N = { '右移标签', ':tabmove +1<CR>' },
        l = { '列出标签', ':tabs<CR>' },
        u = { '恢复关闭标签', ':tabnew #<CR>' },
        d = { '新标签打开目录', ':tabnew .<CR>' },
        f = { '文件浏览器', ':Explore<CR>' },
        F = { '垂直文件浏览器', ':Vexplore<CR>' },
    },
}

-- ---------- 渲染菜单为文本行 ----------
local function is_leaf(item)
    return type(item) == 'table' and item[1] ~= nil
end

local function render_menu(m)
    local leaf_lines, sub_lines = {}, {}
    local keys = {}
    for k in pairs(m) do
        if k ~= 'name' then
            table.insert(keys, k)
        end
    end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local item = m[k]
        if is_leaf(item) then
            table.insert(leaf_lines, string.format(' %-6s %s', k, item[1]))
        else
            local name = item.name or k
            table.insert(sub_lines, string.format(' %-6s <%s>', k, name))
        end
    end

    if #sub_lines > 0 and #leaf_lines > 0 then
        table.insert(leaf_lines, '')
        vim.list_extend(leaf_lines, sub_lines)
        return leaf_lines
    end
    vim.list_extend(leaf_lines, sub_lines)
    return leaf_lines
end

-- ---------- 执行菜单项 ----------
-- 白名单（不静默输出）
local verbose_funcs = {
    [opt.save_and_clear] = true,
    [ws.strip_manual] = true,
    [runner.format] = true,
    [runner.check] = true,
}

local function run_menu_item(item)
    local action = item[2]

    if type(action) == 'function' then
        if verbose_funcs[action] then
            action()
        else
            pcall(action)
        end
    elseif vim.startswith(action, ':') then
        local cmd = action:gsub('<CR>$', '')
        -- 输出型命令不走 silent，否则屏幕不刷新
        if cmd:match('^:%(reg|tabs|marks|jumps|ls|buffers|messages)') then
            vim.cmd(cmd)
        else
            vim.cmd('silent ' .. cmd)
            vim.cmd('redraw')
        end
    else
        vim.cmd('silent normal! ' .. action)
        vim.cmd('redraw')
    end
end

-- ---------- 浮动窗口 ----------
local function open_float(lines, title)
    local width = 0
    for _, l in ipairs(lines) do
        if #l > width then width = #l end
    end
    if width < 24 then width = 24 end

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'

    local height = #lines
    local row = vim.o.lines - height - 5 -- 比默认上移 2 行
    local col = vim.o.columns - width - 5 -- 比默认右移 1 列
    if row < 0 then row = 0 end
    if col < 0 then col = 0 end

    local win = api.nvim_open_win(buf, false, {
        relative = 'editor',
        row = row,
        col = col,
        width = width + 2,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = title,
        title_pos = 'center',
        focusable = false,
    })
    return win
end

-- ---------- 主提示循环 ----------
function M.leader_prompt(silent_mode, from_visual)
    silent_mode = silent_mode or false
    from_visual = from_visual or false

    vim.g.vimore_from_visual = from_visual

    local save_start = vim.fn.getpos("'<")
    local save_end = vim.fn.getpos("'>")
    local save_cur = vim.fn.getpos('.')

    local cur_menu = menu
    local prefix = ''

    while true do
        local lines = render_menu(cur_menu)
        if #lines == 0 then
            lines = { ' (无可用命令)' }
        end

        local title = ' Leader ' .. (prefix == '' and '' or prefix .. ' ')
        if cur_menu.name then
            title = title .. '- ' .. cur_menu.name .. ' '
        end

        local win = nil
        if not silent_mode then
            win = open_float(lines, title)
            vim.cmd('redraw!')
        end

        local char = vim.fn.getcharstr()

        if win and api.nvim_win_is_valid(win) then
            api.nvim_win_close(win, true)
        end
        if not silent_mode then
            vim.cmd('redraw')
        end

        if char == vim.api.nvim_replace_termcodes('<Esc>', true, false, true) then
            return
        end

        local item = cur_menu[char]
        if item ~= nil then
            if is_leaf(item) then
                -- 恢复选区与光标，再执行
                vim.fn.setpos("'<", save_start)
                vim.fn.setpos("'>", save_end)
                vim.fn.setpos('.', save_cur)
                run_menu_item(item)
                return
            else
                prefix = prefix .. char
                cur_menu = item
            end
        elseif cur_menu._ ~= nil then
            run_menu_item(cur_menu._)
            return
        else
            return
        end
    end
end

-- ---------- 映射 ----------
-- 具体映射（如 <Leader>y）优先，停顿 timeoutlen 后才进菜单
vim.keymap.set('n', '<Leader>', function()
    M.leader_prompt(false, false)
end, { silent = true, desc = 'Leader 提示菜单' })
vim.keymap.set('x', '<Leader>', function()
    -- 在映射函数里立即取选区行号，不依赖 '< '>'
    -- v 是可视模式起点，. 是当前光标（选区终点）
    local vstart = vim.fn.line("v")
    local vend = vim.fn.line(".")
    -- v 无效时回退到 '< '>'
    if vstart == 0 then
        vstart = vim.fn.line("'<")
        vend = vim.fn.line("'>")
    end
    if vstart > vend then
        vstart, vend = vend, vstart
    end
    vim.g.vimore_visual_start = vstart
    vim.g.vimore_visual_end = vend
    M.leader_prompt(true, true)
end, { silent = true, desc = 'Leader 提示菜单（可视）' })

return M
