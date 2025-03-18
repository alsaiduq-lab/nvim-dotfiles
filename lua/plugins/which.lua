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
				spelling = {
					enabled = true,
					suggestions = 20,
				},
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
			icons = {
				breadcrumb = "»",
				separator = "➜",
				group = "+",
			},
			defaults = {
				mode = { "n", "v" },
				["<leader>"] = { name = "+prefix" },
			},
			window = {
				border = "rounded",
				position = "bottom",
				margin = { 1, 0, 1, 0 },
				padding = { 2, 2, 2, 2 },
				winblend = 0,
			},
			layout = {
				height = { min = 4, max = 25 },
				width = { min = 20, max = 50 },
				spacing = 3,
				align = "left",
			},
			show_help = true,
			show_keys = true,
			triggers = "<leader>",
			delay = 0,
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)

			wk.register({
				["<leader>f"] = { name = "File", _ = "which_key_ignore" },
				["<leader>ff"] = { "<cmd>Telescope find_files<cr>", "Find File" },
				["<leader>fr"] = { "<cmd>Telescope oldfiles<cr>", "Recent Files" },
				["<leader>fs"] = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
				["<leader>b"] = { name = "Buffer", _ = "which_key_ignore" },
				["<leader>bb"] = { "<cmd>Telescope buffers<cr>", "Switch Buffer" },
				["<leader>bd"] = { "<cmd>bdelete<cr>", "Delete Buffer" },
				["<leader>w"] = { name = "Window", _ = "which_key_ignore" },
				["<leader>wv"] = { "<cmd>vsplit<cr>", "Vertical Split" },
				["<leader>ws"] = { "<cmd>split<cr>", "Horizontal Split" },
				["<leader>wh"] = { "<c-w>h", "Go Left" },
				["<leader>wj"] = { "<c-w>j", "Go Down" },
				["<leader>wk"] = { "<c-w>k", "Go Up" },
				["<leader>wl"] = { "<c-w>l", "Go Right" },
			})
		end,
	},
}
