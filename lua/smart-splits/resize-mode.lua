local M = {}
M.buffers = {}

local keymap_restore = {}
local function smart_autocmd()
    local group_id = vim.api.nvim_create_augroup('smart-splits', { clear = true })
    -- vim.api.nvim_create_autocmd({ 'BufAdd', 'BufNew', 'BufNewFile' }, {
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = "*",
        group = group_id,
        callback = function(buf)
            print("BufEnter", buf)
            buf = buf and buf.buf or vim.api.nvim_get_current_buf()
            print("bufenter: ", buf)

            if not vim.tbl_contains(M.buffers, buf) then
                table.insert(M.buffers, buf)
                local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
                for _, keymap in pairs(keymaps) do
                    if keymap.lhs == 'h' then
                        table.insert(keymap_restore, keymap)
                        vim.api.nvim_buf_del_keymap(buf, 'n', 'h')
                    elseif keymap.lhs == 'j' then
                        table.insert(keymap_restore, keymap)
                        vim.api.nvim_buf_del_keymap(buf, 'n', 'j')
                    elseif keymap.lhs == 'k' then
                        table.insert(keymap_restore, keymap)
                        vim.api.nvim_buf_del_keymap(buf, 'n', 'k')
                    elseif keymap.lhs == 'l' then
                        table.insert(keymap_restore, keymap)
                        vim.api.nvim_buf_del_keymap(buf, 'n', 'l')
                    end
                end
                M.set_buf_to_resize_mode(buf)
            end
        end
    })
end

function M.start_resize_mode()
    if vim.fn.mode() ~= 'n' then
        vim.notify('Resize mode must be triggered from normal mode', vim.log.levels.ERROR)
        return
    end

    M.buffers = vim.api.nvim_list_bufs()
    print("start resize mode")
    print(vim.inspect(M.buffers))
    for _, buf in pairs(M.buffers) do
        local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
        for _, keymap in pairs(keymaps) do
            if keymap.lhs == 'h' then
                table.insert(keymap_restore, keymap)
                vim.api.nvim_buf_del_keymap(buf, 'n', 'h')
            elseif keymap.lhs == 'j' then
                table.insert(keymap_restore, keymap)
                vim.api.nvim_buf_del_keymap(buf, 'n', 'j')
            elseif keymap.lhs == 'k' then
                table.insert(keymap_restore, keymap)
                vim.api.nvim_buf_del_keymap(buf, 'n', 'k')
            elseif keymap.lhs == 'l' then
                table.insert(keymap_restore, keymap)
                vim.api.nvim_buf_del_keymap(buf, 'n', 'l')
            end
        end
        M.set_buf_to_resize_mode(buf)
    end

    -- M.windows = vim.api.nvim_list_wins()
    -- for _, win in ipairs(M.windows) do
    --     if not vim.api.nvim_win_get_config(win).zindex then
    --         local buf = vim.api.nvim_win_get_buf(win)
    --         if not vim.tbl_contains(M.buffers, buf) then
    --             table.insert(M.buffers, buf)
    --         end
    --         M.set_buf_to_resize_mode(buf)
    --     end
    -- end
    vim.api.nvim_set_keymap(
        'n',
        '<ESC>',
        ":lua require('smart-splits.resize-mode').end_resize_mode()<CR>",
        { silent = true }
    )
    smart_autocmd()

    local msg = 'Persistent resize mode enabled. Use h/j/k/l to resize, and <ESC> to finish.'
    print(msg)
    vim.notify(msg, vim.log.levels.INFO)
end

function M.end_resize_mode()
    print("end resize mode")
    print(vim.inspect(M.buffers))
    for _, buf in ipairs(M.buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
            M.set_buf_to_normal_mode(buf)
        end
    end
    for _, keymap in pairs(keymap_restore) do
        if vim.api.nvim_buf_is_valid(keymap.buffer) then
            vim.api.nvim_buf_set_keymap(
                keymap.buffer,
                keymap.mode,
                keymap.lhs,
                keymap.rhs,
                { silent = keymap.silent == 1 }
            )
        end
    end

    vim.api.nvim_del_keymap('n', '<ESC>')
    vim.api.nvim_del_augroup_by_name('smart-splits')

    M.buffers = {}
    -- M.keymap_restore = {}

    local msg = 'Persistent resize mode disabled. Normal keymaps have been restored.'
    print(msg)
    vim.notify(msg, vim.log.levels.INFO)
end

function M.set_buf_to_resize_mode(buf)
    vim.api.nvim_buf_set_keymap(buf, 'n', 'h', ":lua require('smart-splits').resize_left()<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'l', ":lua require('smart-splits').resize_right()<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'j', ":lua require('smart-splits').resize_down()<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'k', ":lua require('smart-splits').resize_up()<CR>", { silent = true })
end

function M.set_buf_to_normal_mode(buf)
    vim.api.nvim_buf_del_keymap(buf, 'n', 'h')
    vim.api.nvim_buf_del_keymap(buf, 'n', 'l')
    vim.api.nvim_buf_del_keymap(buf, 'n', 'j')
    vim.api.nvim_buf_del_keymap(buf, 'n', 'k')
end

return M
