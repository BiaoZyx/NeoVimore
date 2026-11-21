-- ============================================================
-- VimMaze 小游戏加载器
-- 游戏本体在仓库根目录的 VimMaze.vim，按需 source，不拖慢启动
-- ============================================================
local M = {}

local function script_path() return vim.fn.stdpath('config') .. '/VimMaze.vim' end

function M.play()
    local path = script_path()
    if vim.fn.filereadable(path) == 0 then
        vim.notify('vimore: VimMaze.vim not found', vim.log.levels.WARN)
        return
    end

    -- source 之后脚本会定义 :VimMaze，再调用它即可开始游戏
    vim.cmd.source(vim.fn.fnameescape(path))
    pcall(vim.cmd, 'VimMaze')
end

vim.api.nvim_create_user_command('VimMaze', M.play, { desc = 'Start VimMaze' })

return M
