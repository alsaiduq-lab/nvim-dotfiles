return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local notify = require("notify")
		local mason_registry = require("mason-registry")

		lint.linters_by_ft = {
			javascript = { "eslint" },
			typescript = { "eslint" },
			javascriptreact = { "eslint" },
			typescriptreact = { "eslint" },
			python = { "ruff" },
			lua = { "selene" },
			markdown = { "vale" },
			css = { "stylelint" },
			html = { "htmlhint" },
			yaml = { "yamllint" },
			json = { "jsonlint" },
			dockerfile = { "hadolint" },
			sh = { "shellcheck" },
			rust = { "clippy" },
			go = { "golangci-lint" },
			ruby = { "rubocop" },
			php = { "phpcs" },
			c = { "cpplint" },
			cpp = { "cpplint" },
			java = { "checkstyle" },
			xml = { "xmllint" },
			sql = { "sqlfluff" },
			vue = { "eslint" },
			svelte = { "eslint" },
			terraform = { "tflint" },
			proto = { "buf-lint" },
			cmake = { "cmakelint" },
			dart = { "dartanalyzer" },
			kotlin = { "ktlint" },
			scala = { "scalafmt" },
			swift = { "swiftlint" },
			elixir = { "credo" },
			haskell = { "hlint" },
			r = { "lintr" },
			ocaml = { "ocamlformat" },
			nim = { "nimpretty" },
			perl = { "perlcritic" },
			powershell = { "psscriptanalyzer" },
			graphql = { "graphql-lint" },
		}

		local M = {
			timer = nil,
			disabled_linters = {},
		}

		-- Function to get available linters for the current filetype
		local function get_available_linters(ft)
			local linters = lint.linters_by_ft[ft] or {}
			local available_linters = {}

			for _, linter in ipairs(linters) do
				if mason_registry.is_installed(linter) then
					table.insert(available_linters, linter)
				else
					local handle = io.popen("which " .. linter .. " 2>/dev/null")
					if handle then
						local result = handle:read("*a")
						handle:close()
						if result ~= "" then
							table.insert(available_linters, linter)
						end
					end
				end
			end

			return available_linters
		end

		-- Function to pass available linters to Telescope
		local function get_linters_for_telescope()
			local ft = vim.bo.filetype
			local available_linters = get_available_linters(ft)
			local options = {}

			for _, linter in ipairs(available_linters) do
				table.insert(options, {
					label = linter,
					value = linter,
				})
			end

			return options
		end

		-- Try to lint the current buffer
		local function try_lint()
			if M.timer then
				M.timer:stop()
			end

			M.timer = vim.defer_fn(function()
				local bufnr = vim.api.nvim_get_current_buf()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				local ft = vim.bo[bufnr].filetype
				local linters = lint.linters_by_ft[ft] or {}

				-- Filter out disabled linters
				local active_linters = vim.tbl_filter(function(linter)
					return not M.disabled_linters[linter]
				end, linters)

				if #active_linters == 0 then
					return
				end

				-- Check if any of the active linters are available
				local available_linters = get_available_linters(ft)

				if #available_linters == 0 then
					local message = "No available linters for " .. ft
					notify(message, "warn", {
						title = "Linting",
						timeout = 2000,
					})
					return
				end

				-- Debug output to see what linters are available
				print("Available linters for " .. ft .. ": " .. vim.inspect(available_linters))

				local done = false
				vim.defer_fn(function()
					if not done then
						notify("Linting timeout", "error", {
							title = "Linting",
							timeout = 2000,
						})
					end
				end, 10000)

				-- Correctly pass the first available linter to lint.try_lint
				pcall(function()
					for _, linter in ipairs(available_linters) do
						lint.linters[ft] = linter
						lint.try_lint()
						break
					end
					done = true
				end)
			end, 300)
		end

		-- Toggle a specific linter on/off
		local function toggle_linter(linter_name)
			M.disabled_linters[linter_name] = not M.disabled_linters[linter_name]
			local status = M.disabled_linters[linter_name] and "disabled" or "enabled"
			notify(string.format("Linter %s %s", linter_name, status), "info", {
				title = "Linting",
				timeout = 2000,
			})
		end

		-- Setup autocmd to run linting after writing a file
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			callback = try_lint,
		})

		-- Key mappings for linting
		vim.keymap.set("n", "<leader>lt", try_lint, { desc = "   Trigger linting" })
		vim.keymap.set("n", "<leader>lc", function()
			local ft = vim.bo.filetype
			local linters = lint.linters_by_ft[ft] or {}
			if #linters == 0 then
				notify("No linters configured for " .. ft, "warn")
				return
			end

			local options = get_linters_for_telescope()

			vim.ui.select(options, {
				prompt = "Toggle linter for " .. ft,
				format_item = function(item)
					return item.label
				end,
			}, function(choice)
				if choice then
					toggle_linter(choice.value)
				end
			end)
		end, { desc = "   Linters" })

		-- Diagnostic configuration
		vim.diagnostic.config({
			underline = true,
			virtual_text = true,
			signs = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- Custom signs for diagnostics
		local signs = {
			Error = "✖",
			Warn = "⚠",
			Hint = "➤",
			Info = "ℹ",
		}
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end
	end,
}
