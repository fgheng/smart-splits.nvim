local M = {}
M.resize_mode = false
M.buffers = {}
M.windows = {}
M.autocmd_id = nil

local function smart_autocmd()
    M.autocmd_id = vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = "*",
        callback = function(bufnr)
            -- print("smart-splits: BufEnter", bufnr)
            -- print(vim.inspect(bufnr))
            bufnr = bufnr and bufnr.buf or vim.api.nvim_get_current_buf()
            M.set_buf_to_resize_mode(bufnr)
        end
    })
end

function M.start_resize_mode()
    if vim.fn.mode() ~= 'n' then
        vim.notify('Resize mode must be triggered from normal mode', vim.log.levels.ERROR)
        return
    end

    M.windows = vim.api.nvim_list_wins()
    for _, win in ipairs(M.windows) do
        if not vim.api.nvim_win_get_config(win).zindex then
            local buf = vim.api.nvim_win_get_buf(win)
            if not vim.tbl_contains(M.buffers, buf) then
                table.insert(M.buffers, buf)
            end
            M.set_buf_to_resize_mode(buf)
        end
    end
    vim.api.nvim_set_keymap(
        'n',
        '<ESC>',
        ":lua require('smart-splits.resize-mode').end_resize_mode()<CR>",
        { silent = true }
    )
    smart_autocmd()
    M.resize_mode = true

    local msg = 'Persistent resize mode enabled. Use h/j/k/l to resize, and <ESC> to finish.'
    print(msg)
    vim.notify(msg, vim.log.levels.INFO)
end

function M.end_resize_mode()
    for _, buf in ipairs(M.buffers) do
        M.set_buf_to_normal_mode(buf)
    end
    vim.api.nvim_del_keymap('n', '<ESC>')
    vim.api.nvim_delete_autocmd(M.autocmd_id)

    M.buffers = {}
    M.windows = {}
    M.resize_mode = false

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
