-- ============================================================
-- Leader 提示菜单（统一入口）
-- 按 <Space> 立即显示；按 Esc 或菜单里没有的键关闭
-- 普通模式和可视模式都可用，可视模式不会退出选区
-- ============================================================
local M = {}

local api = vim.api
local fn = vim.fn

-- ---------- 依赖 ----------
local opt = require('vimore.options')
local ws = require('vimore.whitespace')
local comment = require('vimore.comment')
local term = require('vimore.terminal')
local runner = require('vimore.runner')

local function notify(msg, level) vim.notify('vimore: ' .. msg, level or vim.log.levels.INFO) end

-- ---------- 小工具 ----------
local function word_count()
    local keys = api.nvim_replace_termcodes('g<C-g>', true, false, true)
    api.nvim_feedkeys(keys, 'n', false)
end

local function git_add()
    local file = fn.expand('%:p')
    if file == '' then
        notify('当前 buffer 没有文件名', vim.log.levels.WARN)
        return
    end
    vim.cmd('!git add ' .. fn.shellescape(file))
end

local function git_commit()
    local msg = fn.input('Commit: ')
    if msg == nil or msg == '' then return end
    vim.cmd('!git commit -m ' .. fn.shellescape(msg))
end

-- 执行命令；可视模式进入菜单时按选区加 range
local function range_cmd(cmd)
    if vim.g.vimore_from_visual then
        vim.cmd("'<,'>" .. cmd)
    else
        vim.cmd(cmd)
    end
end

local function delete_blank_lines() range_cmd([[g/^\s*$/d]]) end

local function sort_lines(kind) range_cmd(kind == 'name' and 'sort' or kind == 'unique' and 'sort u' or 'sort n') end

local function yank_clipboard()
    if vim.g.vimore_from_visual then
        vim.cmd([[normal! gv"+y]])
    else
        vim.cmd([[normal! "+yy]])
    end
end

local function paste_clipboard(before)
    if vim.g.vimore_from_visual then
        vim.cmd([[normal! gv"+p]])
    else
        vim.cmd('normal! "+' .. (before and 'P' or 'p'))
    end
end

local function with_lsp(fn_action)
    return function()
        if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
            notify('当前 buffer 没有 LSP 客户端', vim.log.levels.WARN)
            return
        end
        fn_action()
    end
end

local function lsp_format()
    if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
        notify('当前 buffer 没有 LSP 客户端', vim.log.levels.WARN)
        return
    end
    vim.lsp.buf.format({ async = true })
end

local function open_tutor()
    local path = fn.stdpath('config') .. '/tutor/Vimore.tutor.txt'
    if fn.filereadable(path) == 0 then
        notify('找不到教程文件: ' .. path, vim.log.levels.WARN)
        return
    end
    vim.cmd.edit(fn.fnameescape(path))
end

local function open_health() vim.cmd('checkhealth vimore') end

-- 快捷键总览：把全局映射按模式整理到一个临时 buffer 里
local function show_keys()
    local mode_names = {
        n = '普通模式',
        x = '可视模式',
        i = '插入模式',
        t = '终端模式',
    }
    local lines = { 'Vimore 快捷键总览', '按 q 或 Esc 关闭', '' }

    for _, mode in ipairs({ 'n', 'x', 'i', 't' }) do
        local maps = api.nvim_get_keymap(mode)
        table.sort(maps, function(a, b) return a.lhs < b.lhs end)

        table.insert(lines, '== ' .. mode_names[mode] .. ' ==')
        if #maps == 0 then table.insert(lines, '  (无)') end
        for _, m in ipairs(maps) do
            local lhs = m.lhs ~= '' and m.lhs or '<Nop>'
            local desc = m.desc and m.desc ~= '' and m.desc or ''
            table.insert(lines, string.format('  %-18s %s', lhs, desc))
        end
        table.insert(lines, '')
    end

    vim.cmd('botright new')
    local buf = api.nvim_get_current_buf()
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = 'vimore-keys'
    vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', '<Cmd>close<CR>', { buffer = buf, silent = true })
end

local function reload_config()
    for name in pairs(package.loaded) do
        if name == 'vimore' or name:match('^vimore%.') then package.loaded[name] = nil end
    end
    vim.fn.timer_start(0, function() vim.cmd.source(fn.fnameescape(fn.stdpath('config') .. '/init.lua')) end)
end

-- 给可视选区加括号（照 Vim 版的列处理，兼容多字节字符）
local function char_end_col(line, col)
    if col < 1 or col > #line then return col end
    local ch = line:sub(col):match('^.[\128-\191]*')
    if not ch then return col end
    return col + #ch - 1
end

local function clamp_cols(line, sc, ec)
    local len = #line
    if sc < 1 then sc = 1 end
    if sc > len + 1 then sc = len + 1 end
    if ec > len then ec = len end
    if ec < sc - 1 then ec = sc - 1 end
    if ec >= 1 and ec < len then ec = char_end_col(line, ec) end
    if ec > len then ec = len end
    return sc, ec
end

function M.add_pair(pair)
    local map = { ['('] = ')', ['['] = ']', ['{'] = '}', ['"'] = '"', ["'"] = "'", ['<'] = '>' }
    if map[pair] == nil then
        notify('不支持的括号: ' .. pair, vim.log.levels.WARN)
        return
    end
    if not vim.g.vimore_from_visual then
        notify('需要先在可视模式选中内容', vim.log.levels.WARN)
        return
    end

    local left, right = pair, map[pair]

    local start_pos = fn.getpos("'<")
    local end_pos = fn.getpos("'>")
    if start_pos[2] == 0 or end_pos[2] == 0 then
        notify('没有可视选区', vim.log.levels.WARN)
        return
    end

    local sl, sc = start_pos[2], start_pos[3]
    local el, ec = end_pos[2], end_pos[3]

    if sl > el or (sl == el and sc > ec) then
        sl, sc, el, ec = el, ec, sl, sc
    end

    if sl == el then
        local line = fn.getline(sl)
        sc, ec = clamp_cols(line, sc, ec)
        local prefix = line:sub(1, sc - 1)
        local middle = line:sub(sc, ec)
        local suffix = line:sub(ec + 1)
        fn.setline(sl, prefix .. left .. middle .. right .. suffix)
    else
        local first = fn.getline(sl)
        local last = fn.getline(el)
        local sc1 = clamp_cols(first, sc, #first)
        local _, ec1 = clamp_cols(last, 1, ec)
        local prefix = first:sub(1, sc1 - 1)
        fn.setline(sl, prefix .. left .. first:sub(sc1))
        fn.setline(el, last:sub(1, ec1) .. right .. last:sub(ec1 + 1))
    end
end

-- ---------- 菜单内容 ----------
-- 这是 Leader 下唯一的真值来源；新增命令只改这里即可。
local menu = {
    w = {
        name = '写入',
        w = { '保存', opt.save_and_clear },
        q = { '保存并退出', ':wq' },
        s = { '清理行尾空格', ws.strip_manual },
        c = { '统计字数', word_count },
    },
    q = { '退出', ':quit' },
    W = { '全部保存', ':wall' },
    Q = { '全部退出', ':qall' },
    h = {
        name = '显示',
        h = { '取消搜索高亮', ':nohlsearch' },
        x = { '十六进制模式', ':%!xxd' },
        X = { '退出十六进制', ':%!xxd -r' },
    },
    f = { '格式化代码', runner.format },
    c = {
        name = '维护',
        c = { '代码检查', runner.check },
        k = { '快捷键总览', show_keys },
        v = { '重新加载配置', reload_config },
        e = { '编辑配置', ':edit $MYVIMRC' },
        h = { '运行 :checkhealth', open_health },
        t = { '打开教程', open_tutor },
    },
    ['/'] = { '注释/取消注释', comment.toggle_smart },
    b = {
        name = '括号',
        d = {
            name = '删除指定括号对及其内容',
            ['('] = { '圆括号', ':normal! da(' },
            ['['] = { '方括号', ':normal! da[' },
            ['{'] = { '花括号', ':normal! da{' },
            ['"'] = { '双引号', ':normal! da"' },
            ["'"] = { '单引号', ":normal! da'" },
        },
        a = {
            name = '在可视选区外添加指定括号',
            ['('] = { '圆括号', function() M.add_pair('(') end },
            ['['] = { '方括号', function() M.add_pair('[') end },
            ['{'] = { '花括号', function() M.add_pair('{') end },
            ['"'] = { '双引号', function() M.add_pair('"') end },
            ["'"] = { '单引号', function() M.add_pair("'") end },
            ['<'] = { '尖括号', function() M.add_pair('<') end },
        },
    },
    r = { '查看寄存器', ':reg' },
    z = {
        name = '视图',
        z = { '全部折叠', ':normal! zM' },
        a = { '切换折叠', ':normal! za' },
        Z = { '全部展开', ':normal! zR' },
    },
    y = { '复制到系统剪切板', yank_clipboard },
    p = { '从系统剪切板粘贴', function() paste_clipboard(false) end },
    P = { '从系统剪切板粘贴(前)', function() paste_clipboard(true) end },
    s = {
        name = '整理',
        d = { '删除空行', delete_blank_lines },
        s = { '排序选中行', function() sort_lines('name') end },
        u = { '去重排序', function() sort_lines('unique') end },
        n = { '数字排序', function() sort_lines('number') end },
    },
    g = {
        name = 'Git',
        s = { 'git status', ':!git status' },
        d = { 'git diff', ':!git diff' },
        l = { 'git log', ':!git log --oneline --graph' },
        a = { 'git add', git_add },
        c = { 'git commit', git_commit },
        p = { 'git push', ':!git push' },
        P = { 'git pull', ':!git pull' },
    },
    t = {
        name = '窗口',
        t = { '底部终端', function() term.open('horizontal') end },
        v = { '右侧终端', function() term.open('vertical') end },
        r = { '运行当前文件', term.run_in_latest },
        k = { '切换/关闭终端', term.toggle },
        n = { '新建标签', ':tabnew' },
        e = { '新标签编辑当前', ':tabedit %' },
        c = { '关闭标签', ':tabclose' },
        o = { '保留当前标签', ':tabonly' },
        M = { '左移标签', ':tabmove -1' },
        N = { '右移标签', ':tabmove +1' },
        l = { '列出标签', ':tabs' },
        u = { '新标签打开上一个文件', ':tabnew #' },
        d = { '新标签打开目录', ':tabnew .' },
        f = { '文件浏览器', ':Explore' },
        F = { '垂直文件浏览器', ':Vexplore' },
    },
    l = {
        name = 'LSP',
        d = { '跳转定义', with_lsp(vim.lsp.buf.definition) },
        D = { '跳转声明', with_lsp(vim.lsp.buf.declaration) },
        h = { '悬停文档', with_lsp(vim.lsp.buf.hover) },
        r = { '重命名符号', with_lsp(vim.lsp.buf.rename) },
        a = { '代码操作', with_lsp(vim.lsp.buf.code_action) },
        f = { '格式化', lsp_format },
        e = { '当前行诊断', function() vim.diagnostic.open_float() end },
        q = { '诊断到 quickfix', vim.diagnostic.setqflist },
        n = { '下一个诊断', function() vim.diagnostic.jump({ count = 1 }) end },
        p = { '上一个诊断', function() vim.diagnostic.jump({ count = -1 }) end },
        s = { '文档符号', with_lsp(vim.lsp.buf.document_symbol) },
        S = { '工作区符号', with_lsp(vim.lsp.buf.workspace_symbol) },
        i = { '签名帮助', with_lsp(vim.lsp.buf.signature_help) },
        t = { '类型定义', with_lsp(vim.lsp.buf.type_definition) },
    },
    ['?'] = { '打开教程', open_tutor },
}

-- ---------- 渲染 ----------
local function is_leaf(item) return type(item) == 'table' and item[1] ~= nil end

local function ljust(str, cells)
    local gap = cells - fn.strdisplaywidth(str)
    return str .. string.rep(' ', math.max(0, gap))
end

local function render_lines(node)
    local leaf_lines, sub_lines = {}, {}
    local keys = {}
    for k in pairs(node) do
        if k ~= 'name' then keys[#keys + 1] = k end
    end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local item = node[k]
        if is_leaf(item) then
            leaf_lines[#leaf_lines + 1] = ' ' .. ljust(k, 6) .. ' ' .. item[1]
        else
            sub_lines[#sub_lines + 1] = ' ' .. ljust(k, 6) .. ' <' .. (item.name or k) .. '>'
        end
    end

    local lines = {}
    vim.list_extend(lines, leaf_lines)
    if #leaf_lines > 0 and #sub_lines > 0 then lines[#lines + 1] = '' end
    vim.list_extend(lines, sub_lines)
    return lines
end

local state = {
    active = false,
    node = menu,
    prefix = '',
    from_visual = false,
    win = nil,
    buf = nil,
    gen = 0,
}

local function close_win()
    if state.win and api.nvim_win_is_valid(state.win) then api.nvim_win_close(state.win, true) end
    state.win = nil
    state.buf = nil
end

local function close_menu()
    state.active = false
    state.gen = state.gen + 1
    close_win()
    vim.g.vimore_from_visual = false
end

local function render()
    close_win()

    local lines = render_lines(state.node)
    if #lines == 0 then lines = { ' (无可用命令)' } end

    local width = 24
    for _, line in ipairs(lines) do
        width = math.max(width, fn.strdisplaywidth(line))
    end

    local height = #lines
    local row = math.max(0, vim.o.lines - height - 4)
    local col = math.max(0, vim.o.columns - width - 4)

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'vimore-menu'

    local title = ' Leader '
    if state.prefix ~= '' then title = title .. state.prefix .. ' ' end
    if state.node.name then title = title .. '- ' .. state.node.name .. ' ' end

    state.buf = buf
    state.win = api.nvim_open_win(buf, false, {
        relative = 'editor',
        row = row,
        col = col,
        width = width + 2,
        height = height,
        style = 'minimal',
        border = 'double',
        title = title,
        title_pos = 'center',
        footer = ' Esc 关闭 ',
        footer_pos = 'center',
        focusable = false,
        zindex = 50,
    })

    -- 不用 redraw!，避免可视模式的选区被清掉
    vim.cmd('redraw')

    local gen = state.gen
    vim.defer_fn(function()
        if state.active and state.gen == gen then close_menu() end
    end, vim.g.vimore_menu_timeout or 3000)
end

local function run_menu_item(item)
    local action = item[2]
    local ok, err
    if type(action) == 'function' then
        ok, err = pcall(action)
    elseif type(action) == 'string' and action:sub(1, 1) == ':' then
        local cmd = action:gsub('<CR>$', ''):gsub('^:', '')
        ok, err = pcall(vim.cmd, cmd)
    elseif type(action) == 'string' then
        ok, err = pcall(vim.cmd, 'normal! ' .. action)
    else
        ok, err = false, '未知的菜单动作'
    end
    if not ok then notify(tostring(err), vim.log.levels.ERROR) end
end

local function handle_key(key)
    state.gen = state.gen + 1

    if key == '\27' then -- Esc
        close_menu()
        return ''
    end
    if key == ' ' then -- Leader：再按一次关闭，而不是刷新重开
        close_menu()
        return ''
    end

    local item = state.node[key]
    if item == nil then
        -- 菜单里没有的键：关掉菜单，把键交还给编辑器
        close_menu()
        return nil
    end

    if is_leaf(item) then
        local from_visual = state.from_visual
        close_menu()
        if from_visual then
            -- 先退出可视模式，让 '< '> 标记落到选区上。
            -- 注意 :normal! 不认识 <Esc> 记法，必须用 termcode + feedkeys。
            local esc = api.nvim_replace_termcodes('<Esc>', true, false, true)
            api.nvim_feedkeys(esc, 'nx', false)
        end
        vim.g.vimore_from_visual = from_visual
        local ok, err = pcall(run_menu_item, item)
        vim.g.vimore_from_visual = false
        if not ok then notify(tostring(err), vim.log.levels.ERROR) end
        return ''
    end

    state.node = item
    state.prefix = state.prefix .. key
    if state.from_visual then vim.g.vimore_from_visual = true end
    render()
    return ''
end

local ns = api.nvim_create_namespace('VimoreMenu')
vim.on_key(function(key, _)
    if not state.active then return nil end
    return handle_key(key)
end, ns)

-- ---------- 打开菜单 ----------
function M.open(from_visual)
    if state.active then close_menu() end
    state.active = true
    state.gen = state.gen + 1
    state.node = menu
    state.prefix = ''
    state.from_visual = from_visual == true
    vim.g.vimore_from_visual = state.from_visual
    render()
end

function M.leader_prompt() M.open(false) end

-- 普通模式：按一下空格立即显示
vim.keymap.set('n', '<Leader>', function() M.open(false) end, { silent = true, desc = 'Leader 提示菜单' })

-- 可视模式：回调映射不会退出可视模式，选区保持
vim.keymap.set(
    'x',
    '<Leader>',
    function() M.open(true) end,
    { silent = true, desc = 'Leader 提示菜单（可视）' }
)

vim.api.nvim_create_user_command('VimoreMenu', function() M.open(false) end, { desc = '打开 Vimore Leader 菜单' })

vim.api.nvim_create_user_command('VimoreKeys', show_keys, { desc = '查看 Vimore 快捷键总览' })

M.menu = menu

return M
