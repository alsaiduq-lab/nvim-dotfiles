return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            plugins = {
                marks = true,
                registers = true,
                spelling = { enabled = true, suggestions = 20 },
                presets = {
                    operators = true,
                    motions = true,
                    text_objects = true,
                    windows = true,
                    nav = true,
                    z = true,
                    g = true,
                },
            },
            icons = { breadcrumb = "»", separator = "➜", group = "+" },
            popup = {
                border = "rounded",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 2, 2, 2, 2 },
                winblend = 0,
            },
            layout = { height = { min = 4, max = 25 }, width = { min = 20, max = 50 }, spacing = 3, align = "left" },
            show_help = true,
            show_keys = true,
            triggers = { "<leader>" },
            delay = 0,
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
        end,
    },
}
