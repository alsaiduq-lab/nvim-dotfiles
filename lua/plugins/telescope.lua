return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "nvim-telescope/telescope-fzf-native.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local builtin = require("telescope.builtin")
            local themes = require("telescope.themes")

            local function set_telescope_highlights()
                vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "#5e6687" })
                vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = "#ff79c6" })
                vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = "#3c3e4d", fg = "#f8f8f2" })
            end

            pcall(set_telescope_highlights)

            telescope.setup({
                defaults = {
                    theme = "ivy",
                    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                    path_display = { truncate = 3 },
                    prompt_prefix = " ",
                    selection_caret = " ",
                    sorting_strategy = "ascending",
                    color_devicons = true,
                    file_ignore_patterns = { "node_modules", "%.git/", "target/", "dist/", "%.DS_Store" },
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                    },
                    layout_strategy = "flex",
                    layout_config = {
                        height = 0.4,
                        width = 0.9,
                        prompt_position = "bottom",
                        vertical = {
                            mirror = false,
                            preview_height = 0.5,
                            preview_cutoff = 10,
                        },
                        horizontal = {
                            mirror = false,
                            preview_width = 0.5,
                            preview_cutoff = 10,
                        },
                        flex = {
                            flip_columns = 100,
                            flip_lines = 15,
                        },
                    },
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-q>"] = actions.send_selected_to_qflist,
                            ["<Esc>"] = actions.close,
                        },
                        n = { ["q"] = actions.close },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
                    },
                    live_grep = { additional_args = { "--hidden" } },
                    buffers = { sort_lastused = true, ignore_current_buffer = true, previewer = false },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        themes.get_dropdown({
                            borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                        }),
                    },
                },
            })

            pcall(telescope.load_extension, "fzf")
            pcall(telescope.load_extension, "ui-select")

            vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
            vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
        end,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
}
