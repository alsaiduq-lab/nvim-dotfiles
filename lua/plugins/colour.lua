return {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    config = function()
        require("colorizer").setup({
            ["*"] = {
                RGB = true,
                RRGGBB = true,
                names = true,
                RRGGBBAA = true,
                rgb_fn = true,
                hsl_fn = true,
                css = true,
                css_fn = true,
                mode = "background",
                tailwind = true,
                sass = { enable = true },
                virtualtext = "■",
            }
        })
    end,
}
