return {
	"echasnovski/mini.nvim",
	version = "*",
	config = function()
		require("mini.starter").setup({
			items = {
				{ name = "󰈞 Files", action = "Telescope find_files", section = "Files" },
				{ name = "󰋚 Recent", action = "Telescope oldfiles", section = "Files" },
				{ name = "󰺮 Live Grep", action = "Telescope live_grep", section = "Search" },
				{ name = "󰊢 Git Status", action = "Telescope git_status", section = "Git" },
				{ name = "󰊢 Git Commits", action = "Telescope git_commits", section = "Git" },
				{ name = "󰒲 Lazy", action = "Lazy", section = "Config" },
				{ name = "󰏗 Mason", action = "Mason", section = "Config" },
				{ name = "󰔟 Session", action = "lua MiniSessions.select()", section = "Config" },
			},
			header = table.concat({
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
			}, "\n"),
			content_hooks = {
				require("mini.starter").gen_hook.adding_bullet("→ "),
				require("mini.starter").gen_hook.aligning("center"),
				require("mini.starter").gen_hook.indexing("all", { "Programming", "Files" }),
			},
		})

		require("mini.statusline").setup({
			use_icons = true,
			set_vim_settings = true,
			content = {
				active = function()
					local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
					local git = MiniStatusline.section_git({ trunc_width = 75 })
					local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
					local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
					local location = MiniStatusline.section_location({ trunc_width = 75 })

					return MiniStatusline.combine_groups({
						{ hl = mode_hl, strings = { mode } },
						{ hl = "MiniStatuslineDevinfo", strings = { git } },
						"%<",
						{ hl = "MiniStatuslineFileinfo", strings = { diagnostics } },
						{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
						{ hl = mode_hl, strings = { location } },
					})
				end,
			},
		})

		require("mini.files").setup({
			windows = {
				preview = true,
				width_focus = 30,
				width_preview = 40,
			},
			options = {
				use_as_default_explorer = false,
			},
			mappings = {
				close = "q",
				go_in = "l",
				go_in_plus = "L",
				go_out = "h",
				go_out_plus = "H",
				reset = "<C-r>",
				show_help = "g?",
				synchronize = "=",
				trim_left = "<",
				trim_right = ">",
			},
		})

		require("mini.indentscope").setup({
			symbol = "│",
			options = {
				try_as_border = true,
				border = "both",
				indent_at_cursor = true,
			},
			draw = {
				delay = 100,
				animation = require("mini.indentscope").gen_animation.none(),
			},
		})

		require("mini.surround").setup({
			mappings = {
				add = "sa",
				delete = "sd",
				find = "sf",
				find_left = "sF",
				highlight = "sh",
				replace = "sr",
				update_n_lines = "sn",
			},
			n_lines = 50,
			highlight_duration = 1500,
			custom_surroundings = {
				["*"] = { output = { left = "*", right = "*" } },
				["**"] = { output = { left = "**", right = "**" } },
			},
		})

		require("mini.pairs").setup({
			mappings = {
				["("] = { action = "open", pair = "()", neigh_pattern = "[^\\]." },
				["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\]." },
				["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\]." },
				['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\].", register = { cr = false } },
				["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\].", register = { cr = false } },
				["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].", register = { cr = false } },
			},
			disable_filetype = { "TelescopePrompt" },
			modes = { insert = true, command = false, terminal = false },
		})

		require("mini.ai").setup({
			n_lines = 500,
			custom_textobjects = {
				o = false,
				b = { { "%b()", "%b[]", "%b{}" } },
				q = { { '%b""', "%b''", "%b``" } },
				t = { { "<[^>]*>", "</[^>]*>" } },
			},
			search_method = "cover_or_nearest",
		})

		require("mini.move").setup({
			mappings = {
				left = "<M-h>",
				right = "<M-l>",
				down = "<M-j>",
				up = "<M-k>",
				line_left = "<M-h>",
				line_right = "<M-l>",
				line_down = "<M-j>",
				line_up = "<M-k>",
			},
			options = {
				reindent_linewise = true,
			},
		})

		require("mini.hipatterns").setup({
			highlighters = {
				hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
				todo = { pattern = "TODO:", group = "MiniHipatternsTodo" },
				note = { pattern = "NOTE:", group = "MiniHipatternsNote" },
				fix = { pattern = "FIXME:", group = "MiniHipatternsFix" },
			},
		})

		require("notify").setup({
			lsp_progress = {
				enable = true,
				duration_last = 2000,
			},
			window = {
				winblend = 0,
				max_width = 0.8,
			},
		})

		require("mini.bracketed").setup({
			buffer = { suffix = "b", options = {} },
			comment = { suffix = "c", options = {} },
			conflict = { suffix = "x", options = {} },
			diagnostic = { suffix = "d", options = {} },
			file = { suffix = "f", options = {} },
			indent = { suffix = "i", options = {} },
			jump = { suffix = "j", options = {} },
			location = { suffix = "l", options = {} },
			quickfix = { suffix = "q", options = {} },
			treesitter = { suffix = "t", options = {} },
			undo = { suffix = "u", options = {} },
			window = { suffix = "w", options = {} },
		})

		require("mini.bufremove").setup({
			silent = true,
		})

		require("mini.trailspace").setup({
			only_in_normal_buffers = true,
		})
		require("mini.tabline").setup({
			show_icons = true,
			set_vim_settings = true,
			tabpage_section = "right",
		})

		require("mini.sessions").setup({
			autoread = true,
			autowrite = true,
			directory = "~/.local/share/nvim/sessions",
			file = "Session.vim",
			force = { read = false, write = true, delete = false },
			hooks = {
				pre = {
					write = function()
						vim.cmd("silent! wa")
					end,
				},
			},
			verbose = { read = false, write = true, delete = true },
		})

		require("mini.comment").setup({
			options = {
				custom_commentstring = nil,
				ignore_blank_line = false,
				start_of_line = false,
				pad_comment_parts = true,
			},
		})
		require("mini.cursorword").setup({
			delay = 100,
		})
	end,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
}
