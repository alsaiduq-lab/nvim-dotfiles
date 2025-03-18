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
			lua = { "luacheck", "selene" },
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

		if lint.linters.luacheck then
			lint.linters.luacheck.args = {
				"--globals", "vim",
				"--no-max-line-length",
				"--no-unused-args",
				"-"
			}
		end

		local M = {
			timer = nil,
			disabled_linters = {},
		}

		local function get_available_linters(ft)
			local linters = lint.linters_by_ft[ft] or {}
			local available_linters = {}

			for _, linter in ipairs(linters) do
				if lint.linters[linter] then
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
			end

			return available_linters
		end

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

		local function try_lint()
			if M.timer then
				M.timer:stop()
				M.timer = nil
			end

			M.timer = vim.defer_fn(function()
				local bufnr = vim.api.nvim_get_current_buf()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				local ft = vim.bo[bufnr].filetype
				if ft == "" then
					return
				end

				local linters = lint.linters_by_ft[ft] or {}
				if #linters == 0 then
					return
				end

				local active_linters = vim.tbl_filter(function(linter)
					return not M.disabled_linters[linter]
				end, linters)

				if #active_linters == 0 then
					return
				end

				local available_linters = get_available_linters(ft)
				if #available_linters == 0 then
					return
				end

				lint.try_lint(available_linters)
			end, 300)
		end

		local function toggle_linter(linter_name)
			M.disabled_linters[linter_name] = not M.disabled_linters[linter_name]
			local status = M.disabled_linters[linter_name] and "disabled" or "enabled"
			local icon = M.disabled_linters[linter_name] and "󰜺" or "󰄬"
			notify(string.format("%s Linter %s %s", icon, linter_name, status), "info", {
				title = "󰛩 Linting",
				timeout = 2000,
			})
			if not M.disabled_linters[linter_name] then
				try_lint()
			end
		end

		local function show_linter_status()
			local ft = vim.bo.filetype
			local linters = lint.linters_by_ft[ft] or {}
			local available = get_available_linters(ft)
			if #linters == 0 then
				notify("No linters configured for " .. ft, "warn", {
					title = "󰛩 Linting Status",
				})
				return
			end
			local status_msg = "Linters for " .. ft .. ":\n"
			for _, linter in ipairs(linters) do
				local is_available = vim.tbl_contains(available, linter)
				local is_enabled = not M.disabled_linters[linter]
				local status_icon = is_enabled and "󰄬" or "󰜺"
				local avail_icon = is_available and "󰏫" or "󰏮"
				status_msg = status_msg .. string.format("%s %s %s\n", status_icon, avail_icon, linter)
			end
			notify(status_msg, "info", {
				title = "󰛩 Linting Status",
				timeout = 5000,
			})
		end

		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()
				if vim.api.nvim_buf_is_valid(bufnr) then
					try_lint()
				end
			end,
		})

		vim.keymap.set("n", "<leader>lt", try_lint, { desc = "󰛩  Trigger linting" })
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
		end, { desc = "󰒓  Toggle linters" })
		vim.keymap.set("n", "<leader>ls", show_linter_status, { desc = "󰋼  Show linter status" })

		vim.diagnostic.config({
			underline = true,
			virtual_text = true,
			signs = true,
			update_in_insert = false,
			severity_sort = true,
		})

		local signs = {
			Error = "󰅚 ",
			Warn = "󰀪 ",
			Hint = "󰌶 ",
			Info = "󰋽 ",
		}
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function(ev)
				if ev.buf and vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].filetype ~= "" then
					vim.defer_fn(function()
						if vim.api.nvim_buf_is_valid(ev.buf) then
							try_lint()
						end
					end, 2000)
				end
			end,
		})
	end,
}
