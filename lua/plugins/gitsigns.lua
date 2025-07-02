---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add          = { text = "" },
            change       = { text = "" },
            delete       = { text = "" },
            topdelete    = { text = "" },
            changedelete = { text = "" },
            untracked    = { text = "" },
        },

        current_line_blame            = true,
        current_line_blame_formatter  = "<author>",
        current_line_blame_opts       = {
            virt_text     = true,
            virt_text_pos = "right_align",
            delay         = 0,
        },

        signcolumn       = true,
        watch_gitdir     = { interval = 1000, follow_files = true },
        sign_priority    = 6,
        update_debounce  = 100,
        max_file_length  = 40000,
        preview_config   = {
            border   = "single",
            style    = "minimal",
            relative = "cursor",
            row      = 0,
            col      = 1,
        },

        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
            end

            map("n", "<leader>gh", gs.stage_hunk,               "Stage hunk")
            map("n", "<leader>gr", gs.reset_hunk,               "Reset hunk")
            map("n", "<leader>gp", gs.preview_hunk,             "Preview hunk")
            map("n", "<leader>gb", gs.toggle_current_line_blame,"Toggle blame")

            local blame_on = false
            vim.api.nvim_create_autocmd("CursorHold", {
                buffer = bufnr,
                callback = function()
                    if not blame_on and vim.api.nvim_win_get_width(0) < 80 then
                        gs.toggle_current_line_blame(true)
                        blame_on = true
                    end
                end,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave" }, {
                buffer = bufnr,
                callback = function()
                    if blame_on then
                        gs.toggle_current_line_blame(false)
                        blame_on = false
                    end
                end,
            })
        end,
    },
}
