-- 无第三方依赖的 smoke test
-- 由 tests/run.sh 在隔离的 XDG 目录里启动，自动加载本仓库配置

local function check(cond, msg)
    if not cond then error(msg, 2) end
end

local function feed(keys) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'mx', false) end

local function float_count()
    local n = 0
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative and cfg.relative ~= '' then n = n + 1 end
    end
    return n
end

local function main()
    -- 配置本身
    check(vim.g.mapleader == ' ', 'mapleader 应该是空格')
    check(vim.g.colors_name == 'vimore', '配色没有加载: ' .. tostring(vim.g.colors_name))
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
    check(normal.bg ~= nil or normal.ctermbg ~= nil, 'Normal 应有背景色（hex 或 256 色回退）')
    local expected_t0 = vim.o.termguicolors and '#121217' or 233
    check(vim.g.terminal_color_0 == expected_t0, '终端颜色 0 应跟画布背景一致')
    check(vim.o.number, 'number 没有开启')
    check(vim.o.relativenumber, 'relativenumber 没有开启')
    check(vim.o.signcolumn == 'auto:1', 'signcolumn 应该是 auto:1（不再空占两列）')
    local indent_cases = {
        { '/tmp/vimore-indent.json', 'json', 2, true },
        { '/tmp/vimore-indent.py', 'python', 4, true },
        { '/tmp/vimore-indent.go', 'go', 4, false },
        { '/tmp/vimore-indent.mk', 'make', 8, false },
    }
    for _, c in ipairs(indent_cases) do
        vim.cmd.edit(c[1])
        vim.bo.filetype = c[2]
        vim.api.nvim_exec_autocmds('FileType', { pattern = c[2] })
        check(
            vim.bo.tabstop == c[3] and vim.bo.shiftwidth == c[3] and vim.bo.expandtab == c[4],
            'indent for ' .. c[2] .. ' should be ' .. c[3]
        )
    end
    local cursor_bg = vim.api.nvim_get_hl(0, { name = 'CursorLine' }).bg
    check(
        vim.api.nvim_get_hl(0, { name = 'CursorLineSign' }).bg == cursor_bg,
        '符号列光标行高亮应和正文一致'
    )
    check(
        vim.api.nvim_get_hl(0, { name = 'CursorLineFold' }).bg == cursor_bg,
        '折叠列光标行高亮应和正文一致'
    )
    check(vim.o.list and vim.o.listchars:find('trail:·', 1, true) ~= nil, '行尾空格应显示为 ·')
    check(vim.o.updatetime == 250, 'updatetime 应该是 250')
    check(vim.o.shortmess:find('t', 1, true) ~= nil, 'shortmess 丢了 t')

    -- 命令与模块
    vim.cmd.checkhealth('vimore')
    local health = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    check(health:find('OK', 1, true) ~= nil, 'health 输出缺少状态标记')
    local doc = vim.api.nvim_get_hl(0, { name = '@lsp.typemod.keyword.documentation.lua' })
    local comment = vim.api.nvim_get_hl(0, { name = '@comment' })
    check(doc.fg == comment.fg, 'Lua 文档注释语义 token 应使用注释色')
    -- 指针 * 单独蓝色，运算符保持正文色
    local op_hl = vim.api.nvim_get_hl(0, { name = '@operator' })
    local macro_hl = vim.api.nvim_get_hl(0, { name = 'Macro' })
    check(op_hl.fg == macro_hl.fg, '运算符应使用哑光橙色')
    vim.cmd.enew()
    vim.bo.filetype = 'c'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'int f(int *x) {', '  return *x;', '}' })
    require('vimore.pointer').apply(0)
    local ns = vim.api.nvim_get_namespaces()['vimore.pointer']
    local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    check(#marks == 2, 'C 指针 * 应单独着色: ' .. vim.inspect(marks))
    local ns_op = vim.api.nvim_get_namespaces()['vimore.operator']
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'int x = 1;' })
    require('vimore.pointer').apply(0)
    local opmarks = vim.api.nvim_buf_get_extmarks(0, ns_op, 0, -1, {})
    check(#opmarks == 1 and opmarks[1][3] == 6, 'C 的 = 应着色: ' .. vim.inspect(opmarks))

    vim.bo.filetype = 'python'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'x = 1', 'y = x + 2', 'if x > 0:', 'return a * 2' })
    require('vimore.pointer').apply(0)
    opmarks = vim.api.nvim_buf_get_extmarks(0, ns_op, 0, -1, {})
    check(#opmarks == 5, 'Python 运算符应着色: ' .. vim.inspect(opmarks))
    local ns_sem = vim.api.nvim_get_namespaces()['vimore.semantic']
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'if x > 0:', 'return "hi"', '# comment' })
    require('vimore.pointer').apply(0)
    local sem = vim.api.nvim_buf_get_extmarks(0, ns_sem, 0, -1, { details = true })
    local hls = {}
    for _, m in ipairs(sem) do
        hls[m[4].hl_group] = true
    end
    check(
        hls.Keyword and hls.String and hls.Comment,
        'Python 关键字/字符串/注释应着色: ' .. vim.inspect(hls)
    )
    local ok_f7, err_f7 = pcall(
        function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<F7>', true, false, true), 'x', false) end
    )
    check(ok_f7, 'F7 不应报错: ' .. tostring(err_f7))
    check(vim.b.vimore_wrap_override == true, 'F7 应设置 wrap 覆盖标记')
    check(vim.fn.exists(':VimoreMenu') == 2, ':VimoreMenu 不存在')
    check(vim.fn.exists(':VimoreKeys') == 2, ':VimoreKeys 不存在')
    check(vim.fn.exists(':VimMaze') == 2, ':VimMaze 不存在')
    check(package.loaded['vimore.menu'] ~= nil, 'vimore.menu 没有加载')
    local lsp_count = 0
    for _ in pairs(require('vimore.lsp').servers) do
        lsp_count = lsp_count + 1
    end
    check(lsp_count >= 51, 'LSP 服务器定义应不少于 51 个')
    local menu = require('vimore.menu').menu
    check(menu.w.name == 'Write' and menu.c.name == 'Maintain', 'menu labels should be English')

    -- 标准 Vim 行为没有被改掉
    check(vim.fn.maparg('<', 'n') == '', '普通模式 < 不应该被映射')
    check(vim.fn.maparg('>', 'n') == '', '普通模式 > 不应该被映射')
    check(vim.fn.maparg('<C-t>', 'n') == '', '普通模式 <C-t> 不应该被映射')
    local insert_save = vim.fn.maparg('<C-s>', 'i', false, true)
    check(insert_save.lhs == '<C-S>', '插入模式 <C-s> 应该存在')
    check(
        insert_save.rhs:find('<Cmd>', 1, true) ~= nil,
        '插入模式 <C-s> 应该用 <Cmd>，保存后不离开插入模式'
    )

    -- Leader 菜单：普通模式立即出现，Esc 关闭
    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    feed('<Space>')
    check(vim.wait(1500, function() return float_count() == 1 end), '按空格后菜单没有立即出现')
    feed('<Esc>')
    check(vim.wait(1500, function() return float_count() == 0 end), 'Esc 没有关闭菜单')

    -- 可视模式打开菜单不丢选区
    feed('vll')
    check(vim.wait(1500, function() return vim.fn.mode() == 'v' end), '没有进入可视模式')
    feed('<Space>')
    check(
        vim.wait(1500, function() return float_count() == 1 and vim.fn.mode() == 'v' end),
        '可视模式打开菜单后选区丢了'
    )
    feed('<Esc>')
    check(vim.wait(1500, function() return float_count() == 0 end), 'Esc 没有关闭可视菜单')
    feed('<Esc>')
    check(vim.wait(1500, function() return vim.fn.mode() ~= 'v' end), '第二次 Esc 没有退出可视模式')

    -- 可视选区注释：整块加注释（测试 '< '> 范围是否正确）
    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'a', 'b', 'c' })
    vim.bo.filetype = 'python'
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    feed('V2j')
    check(vim.wait(1500, function() return vim.fn.mode() == 'V' end), '没有进入行可视模式')
    feed('<Space>')
    check(vim.wait(1500, function() return float_count() == 1 end), '可视菜单没有打开')
    feed('/')
    check(
        vim.wait(2000, function() return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '# a' end),
        '可视选区没有整块注释: ' .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))
    )

    -- 保存函数：写入磁盘并清掉 modified
    local save_path = vim.fn.tempname() .. '.txt'
    vim.cmd.edit(vim.fn.fnameescape(save_path))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
    require('vimore.options').save_and_clear()
    check(not vim.bo.modified, 'save_and_clear 没有保存文件')
    check(vim.fn.filereadable(save_path) == 1, 'save_and_clear 没有写入磁盘')
    vim.cmd('enew!')
    vim.fn.delete(save_path)

    -- 括号内回车拆分：尊重 noexpandtab
    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'if ok {}' })
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    require('vimore.completion').split_pair()
    local split = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    check(split[2] == '\t', 'noexpandtab 下应该用制表符，实际: ' .. vim.inspect(split))

    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'if ok {}' })
    vim.bo.expandtab = true
    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    require('vimore.completion').split_pair()
    split = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    check(split[2] == '    ', 'expandtab 下应该用 4 个空格，实际: ' .. vim.inspect(split))

    -- 容器末尾回车：右括号挪到下一行，光标停内容行
    vim.cmd('enew!')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local xs = [1, 2, 3]' })
    vim.api.nvim_win_set_cursor(0, { 1, 19 })
    check(require('vimore.completion').split_container_end(), '容器末尾拆分应该成功')
    split = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    check(split[1] == 'local xs = [', '容器拆分第一行: ' .. vim.inspect(split))
    check(split[2] == '    1,', '容器拆分第一项: ' .. vim.inspect(split))
    check(split[3] == '    2,', '容器拆分第二项: ' .. vim.inspect(split))
    check(split[4] == '    3,', '容器拆分第三项: ' .. vim.inspect(split))
    check(split[5] == ']', '容器拆分右括号行: ' .. vim.inspect(split))
    check(vim.api.nvim_win_get_cursor(0)[1] == 2, '容器拆分后光标应在内容行')

    -- 只删包裹符号 / 换包裹符号
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'foo("bar")' })
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    check(require('vimore.pairs').delete_surround('"'), '删除双引号应成功')
    check(
        vim.api.nvim_get_current_line() == 'foo(bar)',
        '删除双引号应保留内容: ' .. vim.inspect(vim.api.nvim_get_current_line())
    )
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'foo((bar))' })
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    check(require('vimore.pairs').change_surround('"'), '更换包裹符号应成功')
    check(
        vim.api.nvim_get_current_line() == 'foo("bar")',
        '换包裹后内容应保留: ' .. vim.inspect(vim.api.nvim_get_current_line())
    )

    -- Go 文件头：package 按目录推导，不强行生成 main
    local dir = vim.fn.tempname() .. '/mypkg'
    vim.fn.mkdir(dir, 'p')
    vim.cmd('enew!')
    vim.api.nvim_buf_set_name(0, dir .. '/foo.go')
    vim.bo.filetype = 'go'
    require('vimore.header').set_title()
    local header = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    check(header:find('package mypkg', 1, true) ~= nil, 'Go package 推导失败:\n' .. header)
    check(header:find('func main', 1, true) == nil, '非 main 包不应该生成 func main')

    -- 运行命令要对带空格的文件名做 shellescape
    vim.cmd('enew!')
    vim.api.nvim_buf_set_name(0, dir .. '/my file.py')
    vim.bo.filetype = 'python'
    local cmd = require('vimore.terminal').run_command()
    check(cmd:find('my file.py', 1, true) ~= nil, '文件名没有进入命令: ' .. cmd)
    check(cmd:find("'/", 1, true) ~= nil, '路径没有 shellescape: ' .. cmd)

    vim.cmd('enew!')
    vim.fn.delete(dir, 'rf')

    -- 启动期间不应该有错误消息
    local messages = vim.api.nvim_exec2('messages', { output = true }).output
    check(not messages:find('Error detected', 1, true), '启动出现错误:\n' .. messages)
    check(not messages:find('E5113', 1, true), 'Lua 加载出现错误:\n' .. messages)
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
    io.stderr:write(err .. '\n')
    vim.cmd('cq')
end

print('smoke test ok')
vim.cmd('qa!')
