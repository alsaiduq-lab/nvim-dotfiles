return {
	"mhartington/formatter.nvim",
	event = "BufWritePre",
	opts = {},
	config = function()
		local function notify(msg, level)
			local has_notify, nvim_notify = pcall(require, "notify")
			if has_notify then
				nvim_notify(msg, level, {
					title = "Formatter",
					timeout = 1000,
				})
			else
				print(msg)
			end
		end

		require("formatter").setup({
			logging = true,
			log_level = vim.log.levels.WARN,
			filetype = {
				lua = { require("formatter.filetypes.lua").stylua },
				python = {
					function()
						return {
							exe = "black",
							args = {
								"--quiet",
								"-",
							},
							stdin = true,
						}
					end,
				},
				javascript = { require("formatter.filetypes.javascript").prettier },
				typescript = { require("formatter.filetypes.typescript").prettier },
				javascriptreact = { require("formatter.filetypes.javascriptreact").prettier },
				typescriptreact = { require("formatter.filetypes.typescriptreact").prettier },
				json = { require("formatter.filetypes.json").prettier },
				html = { require("formatter.filetypes.html").prettier },
				css = { require("formatter.filetypes.css").prettier },
				scss = { require("formatter.filetypes.css").prettier },
				markdown = { require("formatter.filetypes.markdown").prettier },
				yaml = { require("formatter.filetypes.yaml").yamlfmt },
				rust = { require("formatter.filetypes.rust").rustwind },
				go = { require("formatter.filetypes.go").gofmt },
				["*"] = { require("formatter.filetypes.any").remove_trailing_whitespace },
			},
		})

		local format = require("formatter.format")
		local function format_buffer()
			local bufnr = vim.api.nvim_get_current_buf()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return false
			end

			local win_view = vim.fn.winsaveview()
			local success, err = pcall(format.format)
			if success then
				vim.fn.winrestview(win_view)
				vim.defer_fn(function()
					notify("Formatted file successfully", vim.log.levels.INFO)
				end, 100)
			else
				notify("Format failed: " .. tostring(err), vim.log.levels.ERROR)
			end
		end

		vim.api.nvim_set_keymap("n", "<leader>Fm", ":lua format_buffer()<CR>", { noremap = true, silent = true })

		vim.api.nvim_create_autocmd("TextYankPost", {
			group = vim.api.nvim_create_augroup("AutoFormatOnPaste", { clear = true }),
			callback = function()
				local ft = vim.bo.filetype
				if require("formatter.filetypes")[ft] then
					format_buffer()
				end
			end,
		})
	end,
}
