return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        priority = 100,
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "󰄬",
                        package_pending = "󰦖",
                        package_uninstalled = "󰰱",
                    },
                    border = "rounded",
                    width = 0.8,
                    height = 0.8,
                },
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        priority = 99,
        dependencies = { "williamboman/mason.nvim" },
    },
}
