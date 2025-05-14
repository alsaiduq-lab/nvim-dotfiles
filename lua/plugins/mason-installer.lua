return {
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        lazy = false,
        priority = 90,
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-tool-installer").setup({
                ensure_installed = {
                    "ruff",
                    "alejandra",
                    "prettier",
                    "stylua",
                    "clang-format",
                    "shfmt",
                    "sql-formatter",
                    "yamlfmt",
                    "eslint_d",
                    "luacheck",
                    "markdownlint",
                    "debugpy",
                    "codelldb",
                    "node-debug2-adapter",
                    "js-debug-adapter",
                    "delve",
                    "php-debug-adapter",
                    "bash-debug-adapter",
                },
                auto_update = false,
                run_on_start = false,
                start_delay = 0,
                debounce_hours = 0,
            })
        end,
    },
}

