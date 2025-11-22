return {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    config = function()
        local actions = require("diffview.actions")
        local diffview = require("diffview")
        diffview.setup({
            enhanced_diff_hl = true,
            use_icons = true,
            icons = {
                folder_closed = "",
                folder_open = "",
            },
            signs = {
                fold_closed = "",
                fold_open = "",
                done = "✓",
            },
            view = {
                default = {
                    layout = "diff2_horizontal",
                    winbar_info = false,
                },
                merge_tool = {
                    layout = "diff3_horizontal",
                },
                file_history = {
                    layout = "diff2_horizontal",
                },
            },
            file_panel = {
                listing_style = "tree",
                tree_options = {
                    flatten_dirs = true,
                    folder_statuses = "only_folded",
                },
                win_config = {
                    position = "left",
                    width = 35,
                },
            },
            keymaps = {
                view = {
                    ["q"] = actions.close,
                    ["<tab>"] = actions.select_next_entry,
                    ["<s-tab>"] = actions.select_prev_entry,
                    ["gf"] = actions.goto_file_edit,
                    ["<C-w><C-f>"] = actions.goto_file_split,
                    ["<C-w>gf"] = actions.goto_file_tab,
                    ["[x"] = actions.prev_conflict,
                    ["]x"] = actions.next_conflict,
                },
                file_panel = {
                    ["j"] = actions.next_entry,
                    ["k"] = actions.prev_entry,
                    ["<cr>"] = actions.select_entry,
                    ["o"] = actions.select_entry,
                    ["R"] = actions.refresh_files,
                    ["<tab>"] = actions.select_next_entry,
                    ["<s-tab>"] = actions.select_prev_entry,
                    ["gf"] = actions.goto_file_edit,
                    ["q"] = actions.close,
                },
            },
        })

        local function buffer_diff(bufnr)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            local file_path = vim.api.nvim_buf_get_name(bufnr)

            if file_path == "" then
                vim.notify("Buffer has no file path", vim.log.levels.WARN)
                return
            end

            diffview.open({ file_path })
        end

        vim.keymap.set("n", "<leader>do", "<cmd>DiffviewOpen<CR>", { silent = true, desc = "Git Diff View" })
        vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<CR>", { silent = true, desc = "Close Diff View" })
        vim.keymap.set("n", "<leader>db", buffer_diff, { silent = true, desc = "Buffer Diff View" })
        vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", { silent = true, desc = "File History" })
    end,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
}
