return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
            })
            vim.cmd.colorscheme("tokyonight")
            vim.api.nvim_create_autocmd("VimEnter", {
                callback = function()
                    vim.cmd.colorscheme("tokyonight")
                end,
            })
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 999,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
            })
        end,
    },
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 998,
        config = function()
            require("gruvbox").setup({
                contrast = "hard",
            })
        end,
    },
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 997,
        config = function()
            require("dracula").setup({})
        end,
    },
    {
        "navarasu/onedark.nvim",
        lazy = false,
        priority = 996,
        config = function()
            require("onedark").setup({
                style = "dark",
            })
        end,
    },
    {
        "arcticicestudio/nord-vim",
        lazy = false,
        priority = 995,
    },
    {
        "altercation/vim-colors-solarized",
        lazy = false,
        priority = 994,
        config = function()
            vim.o.background = "dark"
        end,
    },
    {
        "Shatur/neovim-ayu",
        lazy = false,
        priority = 993,
        config = function()
            require("ayu").setup({})
        end,
    },
    {
        "drewtempelmeyer/palenight.vim",
        lazy = false,
        priority = 992,
    },
    {
        "rmehri01/onenord.nvim",
        lazy = false,
        priority = 991,
        config = function()
            require("onenord").setup({})
        end,
    },
    {
        dir = vim.fn.stdpath("config"),
        name = "theme-switcher",
        lazy = false,
        config = function()
            local theme_configs = {
                tokyonight = {
                    name = "TokyoNight",
                    variants = {
                        {
                            name = "Storm",
                            apply = function()
                                require("tokyonight").setup({ style = "storm" })
                                vim.cmd.colorscheme("tokyonight")
                            end,
                        },
                        {
                            name = "Night",
                            apply = function()
                                require("tokyonight").setup({ style = "night" })
                                vim.cmd.colorscheme("tokyonight")
                            end,
                        },
                        {
                            name = "Moon",
                            apply = function()
                                require("tokyonight").setup({ style = "moon" })
                                vim.cmd.colorscheme("tokyonight")
                            end,
                        },
                    },
                },
                catppuccin = {
                    name = "Catppuccin",
                    variants = {
                        {
                            name = "Mocha",
                            apply = function()
                                require("catppuccin").setup({ flavour = "mocha" })
                                vim.cmd.colorscheme("catppuccin")
                            end,
                        },
                        {
                            name = "Latte",
                            apply = function()
                                require("catppuccin").setup({ flavour = "latte" })
                                vim.cmd.colorscheme("catppuccin")
                            end,
                        },
                        {
                            name = "Frappe",
                            apply = function()
                                require("catppuccin").setup({ flavour = "frappe" })
                                vim.cmd.colorscheme("catppuccin")
                            end,
                        },
                        {
                            name = "Macchiato",
                            apply = function()
                                require("catppuccin").setup({ flavour = "macchiato" })
                                vim.cmd.colorscheme("catppuccin")
                            end,
                        },
                    },
                },
                gruvbox = {
                    name = "Gruvbox",
                    variants = {
                        {
                            name = "Default",
                            apply = function()
                                vim.cmd.colorscheme("gruvbox")
                            end,
                        },
                    },
                },
                dracula = {
                    name = "Dracula",
                    variants = {
                        {
                            name = "Default",
                            apply = function()
                                vim.cmd.colorscheme("dracula")
                            end,
                        },
                    },
                },
                onedark = {
                    name = "OneDark",
                    variants = {
                        {
                            name = "Dark",
                            apply = function()
                                require("onedark").setup({ style = "dark" })
                                vim.cmd.colorscheme("onedark")
                            end,
                        },
                        {
                            name = "Darker",
                            apply = function()
                                require("onedark").setup({ style = "darker" })
                                vim.cmd.colorscheme("onedark")
                            end,
                        },
                        {
                            name = "Cool",
                            apply = function()
                                require("onedark").setup({ style = "cool" })
                                vim.cmd.colorscheme("onedark")
                            end,
                        },
                    },
                },
                nord = {
                    name = "Nord",
                    variants = {
                        {
                            name = "Default",
                            apply = function()
                                vim.cmd.colorscheme("nord")
                            end,
                        },
                    },
                },
                solarized = {
                    name = "Solarized",
                    variants = {
                        {
                            name = "Dark",
                            apply = function()
                                vim.o.background = "dark"
                                vim.cmd.colorscheme("solarized")
                            end,
                        },
                        {
                            name = "Light",
                            apply = function()
                                vim.o.background = "light"
                                vim.cmd.colorscheme("solarized")
                            end,
                        },
                    },
                },
                ayu = {
                    name = "Ayu",
                    variants = {
                        {
                            name = "Dark",
                            apply = function()
                                vim.cmd.colorscheme("ayu-dark")
                            end,
                        },
                        {
                            name = "Light",
                            apply = function()
                                vim.cmd.colorscheme("ayu-light")
                            end,
                        },
                        {
                            name = "Mirage",
                            apply = function()
                                vim.cmd.colorscheme("ayu-mirage")
                            end,
                        },
                    },
                },
                palenight = {
                    name = "Palenight",
                    variants = {
                        {
                            name = "Default",
                            apply = function()
                                vim.cmd.colorscheme("palenight")
                            end,
                        },
                    },
                },
                onenord = {
                    name = "OneNord",
                    variants = {
                        {
                            name = "Default",
                            apply = function()
                                vim.cmd.colorscheme("onenord")
                            end,
                        },
                    },
                },
            }

            local function theme_switcher()
                local options = {}
                for _, theme in pairs(theme_configs) do
                    for _, variant in ipairs(theme.variants) do
                        table.insert(options, { display = theme.name .. " " .. variant.name, apply = variant.apply })
                    end
                end
                vim.ui.select(options, {
                    prompt = "Select Theme",
                    format_item = function(item)
                        return item.display
                    end,
                }, function(choice)
                    if choice then
                        choice.apply()
                    end
                end)
            end

            vim.api.nvim_create_user_command("ThemeSelect", theme_switcher, {})
        end,
        vim.keymap.set("n", "<leader>T", ":ThemeSelect<CR>", { noremap = true, silent = true }),

    },
}
