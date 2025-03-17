return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
		"mfussenegger/nvim-dap-python",
		"leoluz/nvim-dap-go",
		"jbyuki/one-small-step-for-vimkind",
		"folke/noice.nvim",
		"rcarriga/nvim-notify",
		"stevearc/dressing.nvim",
		"folke/neodev.nvim",
	},
	lazy = false,
	config = function()
		vim.schedule(function()
			local dap = require("dap")
			local dapui = require("dapui")
			local notify = require("notify")

			vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "🔍", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
			)
			vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "DapLogPoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapStopped",
				{ text = "👉", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
			)

			local function notify_dap(msg, level)
				notify(msg, level, {
					title = "Debugger",
					icon = "🐞",
					timeout = 2000,
				})
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "python",
				callback = function()
					require("dap-python").setup()
					notify_dap("Python debugger configured", "info")
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "go",
				callback = function()
					require("dap-go").setup()
					notify_dap("Go debugger configured", "info")
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "lua",
				callback = function()
					dap.configurations.lua = {
						{
							type = "nlua",
							request = "attach",
							name = "Attach to running Neovim instance",
						},
					}

					dap.adapters.nlua = function(callback, config)
						callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
					end
					notify_dap("Lua debugger configured", "info")
				end,
			})

			require("neodev").setup({
				library = { plugins = { "nvim-dap-ui" }, types = true },
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "javascript", "typescript" },
				callback = function()
					dap.adapters.node2 = {
						type = "executable",
						command = "node",
						args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
					}

					dap.configurations.javascript = {
						{
							type = "node2",
							request = "launch",
							program = "${file}",
							cwd = vim.fn.getcwd(),
							sourceMaps = true,
							protocol = "inspector",
							console = "integratedTerminal",
						},
					}

					dap.configurations.typescript = dap.configurations.javascript
					notify_dap("JavaScript/TypeScript debugger configured", "info")
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "c", "cpp", "rust" },
				callback = function()
					dap.adapters.codelldb = {
						type = "server",
						port = "${port}",
						executable = {
							command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
							args = { "--port", "${port}" },
						},
					}

					dap.configurations.cpp = {
						{
							name = "Launch",
							type = "codelldb",
							request = "launch",
							program = function()
								return vim.fn.input({
									prompt = "Path to executable: ",
									default = vim.fn.getcwd() .. "/",
									completion = "file",
								})
							end,
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
						},
					}

					dap.configurations.c = dap.configurations.cpp
					dap.configurations.rust = dap.configurations.cpp
					notify_dap("C/C++/Rust debugger configured", "info")
				end,
			})

			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
				mappings = {
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						position = "left",
						size = 40,
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						position = "bottom",
						size = 10,
					},
				},
				floating = {
					max_height = nil,
					max_width = nil,
					border = "single",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
				notify_dap("Debug session started", "info")
			end

			dap.listeners.before.event_terminated["dapui_config"] = function()
				notify_dap("Debug session terminated", "warn")
				dapui.close()
			end

			dap.listeners.before.event_exited["dapui_config"] = function()
				notify_dap("Debug session exited", "warn")
				dapui.close()
			end

			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enabled_commands = true,
				highlight_changed_variables = true,
				highlight_new_as_changed = true,
				show_stop_reason = true,
				commented = false,
				virt_text_pos = "eol",
				all_frames = false,
				virt_lines = false,
				virt_text_win_col = nil,
			})

			vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
			vim.keymap.set("n", "<leader>Db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>DB", function()
				dap.set_breakpoint(vim.fn.input({
					prompt = "Breakpoint condition: ",
					completion = "expression",
				}))
			end, { desc = "Conditional Breakpoint" })
			vim.keymap.set("n", "<leader>Dl", function()
				dap.set_breakpoint(
					nil,
					nil,
					vim.fn.input({
						prompt = "Log point message: ",
						completion = "expression",
					})
				)
			end, { desc = "Log Point" })
			vim.keymap.set("n", "<leader>Dr", dap.repl.toggle, { desc = "Toggle REPL" })
			vim.keymap.set("n", "<leader>DL", dap.run_last, { desc = "Run Last" })
			vim.keymap.set("n", "<leader>Dh", function()
				require("dap.ui.widgets").hover()
				notify_dap("Showing debug info", "info")
			end, { desc = "Hover" })
			vim.keymap.set("n", "<leader>Dp", function()
				require("dap.ui.widgets").preview()
			end, { desc = "Preview" })
			vim.keymap.set("n", "<leader>Df", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.frames)
			end, { desc = "Stack Frames" })
			vim.keymap.set("n", "<leader>Ds", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.scopes)
			end, { desc = "Scopes" })
		end)
	end,
}
