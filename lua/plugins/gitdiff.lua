---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    {
        "sindrets/diffview.nvim",
        event = "VeryLazy",
        config = function()
            local actions = require("diffview.actions")
            local diffview = require("diffview")
            local GitDiff = {}
            function GitDiff.buffer_diff(bufnr)
                bufnr = bufnr or vim.api.nvim_get_current_buf()
                local file_path = vim.api.nvim_buf_get_name(bufnr)
                return diffview.open({
                    files = { file_path },
                    enhanced_diff_hl = true,
                })
            end
            function GitDiff.close_diff()
                diffview.close()
            end
            diffview.setup({
                enhanced_diff_hl = true,
                signs = {
                    fold_closed = "",
                    fold_open = "",
                    done = "✓",
                },
                view = {
                    default = {
                        layout = "diff2_horizontal",
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
                    },
                },
            })

            vim.keymap.set("n", "<leader>do", ":DiffviewOpen<CR>", { silent = true, desc = "Git Diff View" })
            vim.keymap.set("n", "<leader>dc", ":DiffviewClose<CR>", { silent = true, desc = "Close Diff View" })
            vim.keymap.set("n", "<leader>db", function()
                GitDiff.buffer_diff()
            end, { silent = true, desc = "Buffer Diff View" })
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },
}
