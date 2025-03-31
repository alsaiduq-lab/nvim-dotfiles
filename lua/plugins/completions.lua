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

			local border_opts = {
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
			}

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(border_opts),
					documentation = cmp.config.window.bordered(border_opts),
				},
				formatting = {
					fields = { "abbr", "kind", "menu" },
					format = function(entry, vim_item)
						local kind = lspkind.cmp_format({
							mode = "symbol_text",
							maxwidth = 50,
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
				},
				experimental = {
					ghost_text = true,
				},
			})

			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
					{
						name = "cmdline",
						option = {
							ignore_cmds = { "Man", "!" },
						},
					},
				}),
			})

			vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = "#569CD6", bold = true })
			vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#569CD6", bold = true })
			vim.api.nvim_set_hl(0, "CmpItemKindVariable", { fg = "#9CDCFE" })
			vim.api.nvim_set_hl(0, "CmpItemKindInterface", { fg = "#9CDCFE" })
			vim.api.nvim_set_hl(0, "CmpItemKindText", { fg = "#9CDCFE" })
			vim.api.nvim_set_hl(0, "CmpItemKindFunction", { fg = "#C586C0" })
			vim.api.nvim_set_hl(0, "CmpItemKindMethod", { fg = "#C586C0" })
			vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { fg = "#D4D4D4" })
			vim.api.nvim_set_hl(0, "CmpItemKindProperty", { fg = "#D4D4D4" })
			vim.api.nvim_set_hl(0, "CmpItemKindUnit", { fg = "#D4D4D4" })
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
