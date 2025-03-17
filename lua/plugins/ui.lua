return {
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = function()
			require("noice").setup({
				cmdline = {
					enabled = true,
					view = "cmdline_popup",
					format = {
						cmdline = { icon = ">" },
						search_down = { icon = "🔍⌄" },
						search_up = { icon = "🔍⌃" },
						filter = { icon = "$" },
						lua = { icon = "☾" },
						help = { icon = "?" },
					},
				},
				messages = {
					enabled = true,
					view = "mini",
					view_error = "mini",
					view_warn = "mini",
					view_history = "messages",
				},
				lsp = {
					progress = {
						enabled = false,
					},
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
				routes = {
					{
						view = "mini",
						filter = {
							cmdline = true,
						},
					},
					{
						filter = {
							event = "msg_showmode",
						},
						view = "mini",
					},
				},
				views = {
					cmdline_popup = {
						border = {
							style = "rounded",
							padding = { 0, 1 },
						},
						position = {
							row = "40%",
							col = "50%",
						},
						size = {
							width = "60%",
							height = "auto",
						},
						win_options = {
							winhighlight = {
								Normal = "Normal",
								FloatBorder = "DiagnosticInfo",
							},
						},
					},
					mini = {
						position = {
							row = -2,
							col = "0",
						},
						size = {
							height = 1,
							width = "100%",
						},
						win_options = {
							winblend = 0,
						},
					},
				},
			})
		end,
	},
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			input = {
				enabled = false,
			},
			select = {
				enabled = true,
				backend = { "telescope", "nui" },
				telescope = require("telescope.themes").get_dropdown({
					border = true,
					previewer = false,
					winblend = 10,
				}),
			},
		},
	},
	{
		"anuvyklack/windows.nvim",
		event = "VeryLazy",
		dependencies = {
			"anuvyklack/middleclass",
			"anuvyklack/animation.nvim",
		},
		config = function()
			require("windows").setup({
				animation = {
					enable = true,
					duration = 150,
				},
				autowidth = {
					enable = true,
					winwidth = 5,
				},
			})
		end,
	},
	{
		"pmizio/typescript-tools.nvim",
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			on_attach = function(client, bufnr)
				local opts = { silent = true, buffer = bufnr }
				vim.keymap.set("n", "Gs", ":TSToolsOrganizeImports<CR>", opts)
				vim.keymap.set("n", "Gi", ":TSToolsRenameFile<CR>", opts)
				vim.keymap.set("n", "Go", ":TSToolsAddMissingImports<CR>", opts)
				vim.keymap.set("n", "Gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "Gk", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			end,
			settings = {
				tsserver_file_preferences = {
					importModuleSpecifierPreference = "non-relative",
				},
			},
		},
	},
}
