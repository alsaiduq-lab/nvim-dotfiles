return {
    "brenoprata10/nvim-highlight-colors",
    event = "BufRead",
    config = function()
        require("nvim-highlight-colors").setup({
            render = "virtual",
            virtual_symbol = "■",
            virtual_symbol_position = "inline",
            enable_tailwind = true,
        })
    end,
}
