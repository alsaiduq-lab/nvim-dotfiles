return {
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "saadparwaiz1/cmp_luasnip",
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            "onsails/lspkind.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")

            require("luasnip.loaders.from_vscode").lazy_load()

            vim.g.cmp_autocomplete_enabled = true
            vim.g.cmp_documentation_enabled = true
            local default_autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged }
            local border_opts = {
                border = "rounded",
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            }

            local function set_cmp_autocomplete(enabled)
                cmp.setup.buffer({
                    completion = {
                        autocomplete = enabled and default_autocomplete or false,
                    },
                })
            end

            local function toggle_cmp_autocomplete()
                vim.g.cmp_autocomplete_enabled = not vim.g.cmp_autocomplete_enabled
                set_cmp_autocomplete(vim.g.cmp_autocomplete_enabled)
                vim.notify(
                    "Autocomplete is now " .. (vim.g.cmp_autocomplete_enabled and "enabled" or "disabled"),
                    vim.log.levels.INFO
                )
            end

            vim.api.nvim_create_user_command("CmpToggleAutocomplete", toggle_cmp_autocomplete, {})
            vim.keymap.set("n", "<leader>A", toggle_cmp_autocomplete, { desc = "Toggle autocompletions" })

            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                    set_cmp_autocomplete(vim.g.cmp_autocomplete_enabled)
                end,
            })

            local function toggle_cmp_documentation()
                vim.g.cmp_documentation_enabled = not vim.g.cmp_documentation_enabled

                cmp.setup({
                    window = {
                        completion = cmp.config.window.bordered(border_opts),
                        documentation = vim.g.cmp_documentation_enabled and cmp.config.window.bordered(border_opts)
                            or cmp.config.disable,
                    },
                })

                cmp.close()
                vim.notify(
                    "Documentation is now "
                        .. (vim.g.cmp_documentation_enabled and "enabled" or "disabled")
                        .. ". Change takes effect on the next completion popup.",
                    vim.log.levels.INFO
                )
            end

            vim.keymap.set("n", "<leader>ad", toggle_cmp_documentation, { desc = "Toggle documentation" })

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(border_opts),
                    documentation = vim.g.cmp_documentation_enabled and cmp.config.window.bordered(border_opts)
                        or cmp.config.disable,
                },
                formatting = {
                    fields = { "abbr", "kind", "menu" },
                    format = function(entry, vim_item)
                        local kind = lspkind.cmp_format({
                            mode = "symbol_text",
                            maxwidth = 40,
                            preset = "codicons",
                            menu = {
                                buffer = "[Buffer]",
                                nvim_lsp = "[LSP]",
                                nvim_lua = "[API]",
                                path = "[Path]",
                                luasnip = "[Snip]",
                                cmdline = "[CMD]",
                            },
                        })(entry, vim_item)

                        local label = vim_item.abbr
                        local truncated_label = vim.fn.strcharpart(label, 0, 30)
                        if truncated_label ~= label then
                            vim_item.abbr = truncated_label .. "…"
                        end

                        return kind
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
                    ["<PageUp>"] = cmp.mapping.scroll_docs(-4),
                    ["<PageDown>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({
                        select = false,
                        behavior = cmp.ConfirmBehavior.Replace,
                    }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "luasnip", priority = 750 },
                    { name = "buffer", priority = 500 },
                    { name = "path", priority = 250 },
                }),
                completion = {
                    completeopt = "menu,menuone,noinsert",
                    autocomplete = vim.g.cmp_autocomplete_enabled and default_autocomplete or false,
                },
                experimental = {
                    ghost_text = true,
                },
                performance = {
                    debounce = 60,
                    throttle = 30,
                    fetching_timeout = 500,
                },
            })

            cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })
            cmp.setup.cmdline("?", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                    { name = "cmdline" },
                }),
            })

            vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = "#82aaff", bold = true })
            vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#82aaff", bold = true })
            vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = "#b0b4bc" })
            vim.api.nvim_set_hl(0, "CmpItemKindVariable", { fg = "#c3e88d" })
            vim.api.nvim_set_hl(0, "CmpItemKindFunction", { fg = "#82aaff" })
            vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { fg = "#f78c6c" })
            vim.api.nvim_set_hl(0, "CmpItemKindText", { fg = "#ffcb6b" })
            vim.api.nvim_set_hl(0, "CmpItemKindSnippet", { fg = "#c792ea" })
            vim.api.nvim_set_hl(0, "CmpItemKindMethod", { fg = "#89ddff" })
            vim.api.nvim_set_hl(0, "CmpItemKindProperty", { fg = "#b0b4bc" })
            vim.api.nvim_set_hl(0, "CmpItemKindUnit", { fg = "#b0b4bc" })
            vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#686868" })
            vim.api.nvim_set_hl(0, "Pmenu", { bg = "#23283b" })
            vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#282f49" })
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#23283b" })
            vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#2d3a57", bg = "#23283b" })
        end,
    },

    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        opts = {
            history = true,
            updateevents = "TextChanged,TextChangedI",
            delete_check_events = "TextChanged,InsertLeave",
        },
        config = function(_, opts)
            require("luasnip").setup(opts)
        end,
    },
}
