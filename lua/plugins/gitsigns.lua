return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "" },
            change = { text = "" },
            delete = { text = "" },
            topdelete = { text = "" },
            changedelete = { text = "" },
            untracked = { text = "" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
            interval = 1000,
            follow_files = true,
        },
        attach_to_untracked = false,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 1000,
        },
        sign_priority = 6,
        update_debounce = 100,
        max_file_length = 40000,
        preview_config = {
            border = "single",
            style = "minimal",
            relative = "cursor",
            row = 0,
            col = 1,
        },
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end
            map("n", "<leader>gh", gs.stage_hunk, { desc = "Stage hunk" })
            map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
            map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
            map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
        end,
    },
}
