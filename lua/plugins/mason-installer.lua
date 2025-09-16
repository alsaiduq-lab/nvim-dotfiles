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
                    "prettier",
                    "stylua",
                    "clang-format",
                    "shfmt",
                    "eslint_d",
                    "codelldb",
                    "delve",
                },
                auto_update = false,
                run_on_start = false,
                start_delay = 0,
                debounce_hours = 0,
            })
        end,
    },
}
