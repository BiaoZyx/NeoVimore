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
        notify('Current buffer has no file name', vim.log.levels.WARN)
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
            notify('No LSP client attached to this buffer', vim.log.levels.WARN)
            return
        end
        fn_action()
    end
end

local function lsp_format()
    if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
        notify('No LSP client attached to this buffer', vim.log.levels.WARN)
        return
    end
    vim.lsp.buf.format({ async = true })
end

local function open_tutor()
    local path = fn.stdpath('config') .. '/tutor/Vimore.tutor.txt'
    if fn.filereadable(path) == 0 then
        notify('Tutorial file not found: ' .. path, vim.log.levels.WARN)
        return
    end
    vim.cmd.edit(fn.fnameescape(path))
end

local function open_health() vim.cmd('checkhealth vimore') end

-- 快捷键总览：把全局映射按模式整理到一个临时 buffer 里
local function show_keys()
    local mode_names = {
        n = 'Normal',
        x = 'Visual',
        i = 'Insert',
        t = 'Terminal',
    }
    local lines = { 'Vimore keymaps', 'Press q or Esc to close', '' }

    for _, mode in ipairs({ 'n', 'x', 'i', 't' }) do
        local maps = api.nvim_get_keymap(mode)
        table.sort(maps, function(a, b) return a.lhs < b.lhs end)

        table.insert(lines, '== ' .. mode_names[mode] .. ' ==')
        if #maps == 0 then table.insert(lines, '  (none)') end
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
        notify('Unsupported bracket: ' .. pair, vim.log.levels.WARN)
        return
    end
    if not vim.g.vimore_from_visual then
        notify('Select text in Visual mode first', vim.log.levels.WARN)
        return
    end

    local left, right = pair, map[pair]

    local start_pos = fn.getpos("'<")
    local end_pos = fn.getpos("'>")
    if start_pos[2] == 0 or end_pos[2] == 0 then
        notify('No visual selection', vim.log.levels.WARN)
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
        name = 'Write',
        w = { 'Save', opt.save_and_clear },
        q = { 'Save and quit', ':wq' },
        s = { 'Strip trailing whitespace', ws.strip_manual },
        c = { 'Word count', word_count },
    },
    q = { 'Quit', ':quit' },
    W = { 'Save all', ':wall' },
    Q = { 'Quit all', ':qall' },
    h = {
        name = 'Display',
        h = { 'Clear search highlight', ':nohlsearch' },
        x = { 'Hex mode', ':%!xxd' },
        X = { 'Exit hex mode', ':%!xxd -r' },
    },
    f = { 'Format code', runner.format },
    c = {
        name = 'Maintain',
        c = { 'Check code', runner.check },
        k = { 'Keymap overview', show_keys },
        v = { 'Reload config', reload_config },
        e = { 'Edit config', ':edit $MYVIMRC' },
        h = { 'Run :checkhealth', open_health },
        t = { 'Open tutorial', open_tutor },
    },
    ['/'] = { 'Toggle comment', comment.toggle_smart },
    b = {
        name = 'Brackets',
        d = {
            name = 'Delete pair and contents',
            ['('] = { 'Parentheses', ':normal! da(' },
            ['['] = { 'Square brackets', ':normal! da[' },
            ['{'] = { 'Braces', ':normal! da{' },
            ['"'] = { 'Double quote', ':normal! da"' },
            ["'"] = { 'Single quote', ":normal! da'" },
        },
        a = {
            name = 'Wrap visual selection',
            ['('] = { 'Parentheses', function() M.add_pair('(') end },
            ['['] = { 'Square brackets', function() M.add_pair('[') end },
            ['{'] = { 'Braces', function() M.add_pair('{') end },
            ['"'] = { 'Double quote', function() M.add_pair('"') end },
            ["'"] = { 'Single quote', function() M.add_pair("'") end },
            ['<'] = { 'Angle brackets', function() M.add_pair('<') end },
        },
    },
    r = { 'Show registers', ':reg' },
    z = {
        name = 'View',
        z = { 'Fold all', ':normal! zM' },
        a = { 'Toggle fold', ':normal! za' },
        Z = { 'Unfold all', ':normal! zR' },
    },
    y = { 'Yank to clipboard', yank_clipboard },
    p = { 'Paste from clipboard', function() paste_clipboard(false) end },
    P = { 'Paste from clipboard (before)', function() paste_clipboard(true) end },
    s = {
        name = 'Sort / clean',
        d = { 'Delete blank lines', delete_blank_lines },
        s = { 'Sort lines', function() sort_lines('name') end },
        u = { 'Sort unique', function() sort_lines('unique') end },
        n = { 'Sort numeric', function() sort_lines('number') end },
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
        name = 'Window',
        t = { 'Terminal (bottom)', function() term.open('horizontal') end },
        v = { 'Terminal (right)', function() term.open('vertical') end },
        r = { 'Run current file', term.run_in_latest },
        k = { 'Toggle terminal', term.toggle },
        n = { 'New tab', ':tabnew' },
        e = { 'Edit in new tab', ':tabedit %' },
        c = { 'Close tab', ':tabclose' },
        o = { 'Keep only this tab', ':tabonly' },
        M = { 'Move tab left', ':tabmove -1' },
        N = { 'Move tab right', ':tabmove +1' },
        l = { 'List tabs', ':tabs' },
        u = { 'Open alternate file in tab', ':tabnew #' },
        d = { 'Open directory in tab', ':tabnew .' },
        f = { 'File explorer', ':Explore' },
        F = { 'Vertical file explorer', ':Vexplore' },
    },
    l = {
        name = 'LSP',
        d = { 'Go to definition', with_lsp(vim.lsp.buf.definition) },
        D = { 'Go to declaration', with_lsp(vim.lsp.buf.declaration) },
        h = { 'Hover docs', with_lsp(vim.lsp.buf.hover) },
        r = { 'Rename symbol', with_lsp(vim.lsp.buf.rename) },
        a = { 'Code action', with_lsp(vim.lsp.buf.code_action) },
        f = { 'Format (LSP)', lsp_format },
        e = { 'Line diagnostics', function() vim.diagnostic.open_float() end },
        q = { 'Diagnostics to quickfix', vim.diagnostic.setqflist },
        n = { 'Next diagnostic', function() vim.diagnostic.jump({ count = 1 }) end },
        p = { 'Previous diagnostic', function() vim.diagnostic.jump({ count = -1 }) end },
        s = { 'Document symbols', with_lsp(vim.lsp.buf.document_symbol) },
        S = { 'Workspace symbols', with_lsp(vim.lsp.buf.workspace_symbol) },
        i = { 'Signature help', with_lsp(vim.lsp.buf.signature_help) },
        t = { 'Type definition', with_lsp(vim.lsp.buf.type_definition) },
    },
    ['?'] = { 'Open tutorial', open_tutor },
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
    if #lines == 0 then lines = { ' (no commands available)' } end

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
        footer = ' Esc to close ',
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
        ok, err = false, 'Unknown menu action'
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
        -- 关键：菜单动作要离开 on_key 回调再执行。否则动作里的
        -- startinsert() 会被按键处理流程吞掉，终端停在普通模式。
        vim.defer_fn(function()
            local ok, err = pcall(run_menu_item, item)
            vim.g.vimore_from_visual = false
            if not ok then notify(tostring(err), vim.log.levels.ERROR) end
        end, 1)
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
vim.keymap.set('n', '<Leader>', function() M.open(false) end, { silent = true, desc = 'Leader menu' })

-- 可视模式：回调映射不会退出可视模式，选区保持
vim.keymap.set('x', '<Leader>', function() M.open(true) end, { silent = true, desc = 'Leader menu (Visual)' })

vim.api.nvim_create_user_command('VimoreMenu', function() M.open(false) end, { desc = 'Open Vimore Leader menu' })

vim.api.nvim_create_user_command('VimoreKeys', show_keys, { desc = 'Show Vimore keymaps' })

M.menu = menu

return M
