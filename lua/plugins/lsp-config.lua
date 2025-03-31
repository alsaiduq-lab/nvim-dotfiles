return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		priority = 100,
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "󰄬",
						package_pending = "󰦖",
						package_uninstalled = "󰰱",
					},
					border = "rounded",
					check_outdated_packages_on_open = false,
					width = 0.8,
					height = 0.8,
					keymaps = {
						toggle_package_expand = "<CR>",
						install_package = "i",
						update_package = "u",
						check_package_version = "c",
						update_all_packages = "U",
						check_outdated_packages = "C",
						uninstall_package = "X",
					},
				},
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		priority = 90,
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			local state_file = vim.fn.stdpath("data") .. "/mason_tools_installed"
			local tools_installed = false

			local f = io.open(state_file, "r")
			if f then
				tools_installed = true
				f:close()
			end

			local function is_executable(cmd)
				return vim.fn.executable(cmd) == 1
			end

			local system_installed_tools = {
				["ruff"] = is_executable("ruff"),
				["prettier"] = is_executable("prettier"),
				["stylua"] = is_executable("stylua"),
				["clang-format"] = is_executable("clang-format"),
				["shfmt"] = is_executable("shfmt"),
				["sql-formatter"] = is_executable("sql-formatter"),
				["yamlfmt"] = is_executable("yamlfmt"),
				["eslint"] = is_executable("eslint"),
				["luacheck"] = is_executable("luacheck"),
				["markdownlint"] = is_executable("markdownlint"),
				["alejandra"] = is_executable("alejandra"),
				["shellcheck"] = is_executable("shellcheck"),
				["debugpy"] = is_executable("python") and pcall(require, "debugpy"),
			}

			local system_tools = {}
			for tool, installed in pairs(system_installed_tools) do
				if installed then
					table.insert(system_tools, tool)
				end
			end

			local function filter_tools(tools)
				local filtered = {}
				for _, tool in ipairs(tools) do
					local tool_name = tool:match("^.*/(.+)$") or tool
					if not system_installed_tools[tool_name] then
						table.insert(filtered, tool)
					end
				end
				return filtered
			end

			local base_tools = {
				"alejandra",
				"prettier",
				"stylua",
				"clang-format",
				"shfmt",
				"sql-formatter",
				"yamlfmt",

				"eslint",
				"luacheck",
				"markdownlint",

				"debugpy",
				"codelldb",
				"node-debug2-adapter",
				"js-debug-adapter",
				"delve",
				"php-debug-adapter",
				"bash-debug-adapter",
			}

			local ensure_installed = filter_tools(base_tools)

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = false,
				start_delay = 3000,
				debounce_hours = 24,
			})

			if not tools_installed and #ensure_installed > 0 then
				vim.defer_fn(function()
					local success, err = pcall(function()
						vim.cmd("MasonToolsInstall")
					end)

					if success then
						local state = io.open(state_file, "w")
						if state then
							state:write("installed")
							state:close()
						end
					else
						vim.notify("Mason tools installation failed: " .. tostring(err), vim.log.levels.WARN, {
							title = "Mason",
							timeout = 3000,
						})
					end
				end, 5000)
			end

			vim.api.nvim_create_user_command("MasonToolsForceInstall", function()
				local success, err = pcall(function()
					vim.cmd("MasonToolsInstall")
				end)

				if success then
					vim.notify("Mason tools installation complete", vim.log.levels.INFO, {
						title = "Mason",
						timeout = 1500,
					})
				else
					vim.notify("Mason tools installation failed: " .. tostring(err), vim.log.levels.WARN, {
						title = "Mason",
						timeout = 2000,
					})
				end
			end, { desc = "Force Mason tools installation" })

			vim.api.nvim_create_user_command("MasonSystemTools", function()
				local system_msg = "System-installed tools: "
					.. (#system_tools > 0 and table.concat(system_tools, ", ") or "none")
				local mason_msg = "Mason-installed tools: "
					.. (#ensure_installed > 0 and table.concat(ensure_installed, ", ") or "none")
				vim.notify(system_msg .. "\n\n" .. mason_msg, vim.log.levels.INFO, {
					title = "Development Tools",
					timeout = 5000,
				})
			end, { desc = "Show system vs Mason tools" })
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			local function is_executable(cmd)
				return vim.fn.executable(cmd) == 1
			end

			local system_installed_lsp = {
				["rust_analyzer"] = is_executable("rust-analyzer"),
				["clangd"] = is_executable("clangd"),
				["eslint"] = is_executable("eslint"),
				["gopls"] = is_executable("gopls"),
				["lua_ls"] = is_executable("lua-language-server"),
				["pyright"] = is_executable("pyright"),
				["nil_ls"] = is_executable("nil"),
			}

			local system_lsp = {}
			for server, installed in pairs(system_installed_lsp) do
				if installed then
					table.insert(system_lsp, server)
				end
			end

			local base_lsp_servers = {
				"rust_analyzer",
				"clangd",
				"cssls",
				"denols",
				"eslint",
				"gopls",
				"html",
				"jsonls",
				"lua_ls",
				"marksman",
				"nil_ls",
				"pyright",
				"taplo",
				"yamlls",
			}

			local ensure_installed = {}
			for _, server in ipairs(base_lsp_servers) do
				if not system_installed_lsp[server] then
					table.insert(ensure_installed, server)
				end
			end

			require("mason-lspconfig").setup({
				ensure_installed = ensure_installed,
				automatic_installation = true,
			})

			vim.api.nvim_create_user_command("MasonSystemLSP", function()
				local system_msg = "System-installed LSP servers: "
					.. (#system_lsp > 0 and table.concat(system_lsp, ", ") or "none")
				local mason_msg = "Mason-installed LSP servers: "
					.. (#ensure_installed > 0 and table.concat(ensure_installed, ", ") or "none")
				vim.notify(system_msg .. "\n\n" .. mason_msg, vim.log.levels.INFO, {
					title = "LSP Servers",
					timeout = 5000,
				})
			end, { desc = "Show system vs Mason LSP servers" })
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("mason-nvim-dap").setup({
				automatic_installation = false,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
				},
			})
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("dap-vscode-js").setup({
				debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
				adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
			})

			local dap = require("dap")

			for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
				dap.configurations[language] = {
					{
						type = "pwa-chrome",
						request = "launch",
						name = "Launch browser against localhost",
						url = "http://localhost:3000",
						webRoot = "${workspaceFolder}",
						sourceMaps = true,
						protocol = "inspector",
						port = 9222,
						skipFiles = { "<node_internals>/**", "node_modules/**" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch Node.js Program",
						program = "${file}",
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						protocol = "inspector",
						skipFiles = { "<node_internals>/**", "node_modules/**" },
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach to Node.js Process",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
					},
				}
			end
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
			"b0o/schemastore.nvim",
			"nvimdev/lspsaga.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")
			local lspkind = require("lspkind")
			lspkind.init()
			vim.opt.signcolumn = "yes"

			require("lspsaga").setup({
				ui = {
					border = "rounded",
					code_action = "󰌵",
					colors = {
						normal_bg = "#1a1b26",
					},
				},
				lightbulb = {
					enable = true,
					sign = true,
					virtual_text = true,
				},
				symbol_in_winbar = {
					enable = true,
					show_file = true,
				},
				hover = {
					max_width = 0.6,
					open_link = "gx",
				},
				rename = {
					in_select = false,
					auto_save = true,
				},
				diagnostic = {
					on_insert = false,
					show_code_action = true,
					show_virt_line = true,
					show_source = true,
				},
			})

			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities()
			)

			local function setup_enhanced_diagnostics()
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

				vim.diagnostic.config({
					virtual_text = {
						prefix = "󰧞",
						source = true,
						severity_sort = true,
					},
					float = {
						source = true,
						border = "rounded",
						header = "",
						prefix = "",
					},
					signs = true,
					underline = true,
					update_in_insert = false,
					severity_sort = true,
				})

				vim.api.nvim_create_user_command("DiagnosticNext", function()
					vim.diagnostic.goto_next()
					vim.defer_fn(function()
						vim.lsp.buf.code_action()
					end, 100)
				end, { desc = "Go to next diagnostic and show fixes" })

				vim.api.nvim_create_user_command("DiagnosticPrev", function()
					vim.diagnostic.goto_prev()
					vim.defer_fn(function()
						vim.lsp.buf.code_action()
					end, 100)
				end, { desc = "Go to previous diagnostic and show fixes" })

				vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc = "Previous Diagnostic" })
				vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next Diagnostic" })
				vim.keymap.set(
					"n",
					"<leader>e",
					"<cmd>Lspsaga show_cursor_diagnostics<CR>",
					{ desc = "Show Diagnostic Details" }
				)
				vim.keymap.set(
					"n",
					"<leader>q",
					vim.diagnostic.setloclist,
					{ desc = "Add Diagnostics to Location List" }
				)
			end

			local function open_dynamic_lsp_log()
				local log_path = vim.lsp.get_log_path()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_get_name(buf) == log_path then
						vim.api.nvim_set_current_buf(buf)
						return
					end
				end
				vim.cmd("vnew")
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_name(buf, "LSP Log")
				vim.bo[buf].buftype = "nofile"
				vim.bo[buf].modifiable = false
				local tail_command = "tail -f " .. log_path
				vim.fn.termopen(tail_command, {
					on_exit = function()
						vim.api.nvim_buf_delete(buf, { force = true })
					end,
				})
			end

			pcall(setup_enhanced_diagnostics)

			vim.api.nvim_create_user_command(
				"DynamicLspLog",
				open_dynamic_lsp_log,
				{ desc = "Open dynamic LSP log in a buffer" }
			)
			vim.keymap.set("n", "<leader>dl", ":DynamicLspLog<CR>", { desc = "Open dynamic LSP log" })

			local function is_executable(cmd)
				return vim.fn.executable(cmd) == 1
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					local opts = { buffer = event.buf }
					vim.keymap.set("n", "Ld", "<cmd>Lspsaga goto_definition<CR>", opts)
					vim.keymap.set("n", "LD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "Li", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "Lo", "<cmd>Lspsaga peek_type_definition<CR>", opts)
					vim.keymap.set("n", "Lr", "<cmd>Lspsaga finder<CR>", opts)
					vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
					vim.keymap.set("n", "Ls", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts)
					vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)
					vim.keymap.set({ "n", "x" }, "<F3>", function()
						vim.lsp.buf.format({ async = true })
					end, opts)
					vim.keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Toggle Symbol Outline" })
					local diagnostic_augroup = vim.api.nvim_create_augroup("Diagnostic", { clear = true })
				end,
			})

			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = {
									"vim",
									"describe",
									"it",
									"before_each",
									"after_each",
									"awesome",
									"client",
									"screen",
									"mouse",
									"use",
								},
								disable = {
									"missing-parameter",
									"missing-fields",
								},
							},
							completion = {
								callSnippet = "Replace",
								keywordSnippet = "Replace",
								displayContext = 6,
							},
							format = {
								enable = true,
								defaultConfig = {
									indent_style = "space",
									indent_size = "2",
								},
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
								maxPreload = 2000,
								preloadFileSize = 1000,
							},
							telemetry = { enable = false },
							hint = {
								enable = true,
								setType = true,
								paramType = true,
								paramName = "Literal",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
						},
					},
				},

				cssls = {},
				html = {},
				eslint = {},
				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
						},
					},
				},

				yamlls = {
					settings = {
						yaml = {
							schemaStore = {
								enable = true,
								url = "https://www.schemastore.org/api/json/catalog.json",
							},
						},
					},
				},
				denols = {},
				gopls = {
					settings = {
						gopls = {
							analyses = {
								unusedparams = true,
							},
							staticcheck = true,
						},
					},
				},
				pyright = {
					settings = {
						python = {
							analysis = {
								typeCheckingMode = "basic",
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "workspace",
							},
						},
						ruff = {
							lint = {
								run = "onSave",
							},
						},
					},
				},
				rust_analyzer = {
					settings = {
						["rust-analyzer"] = {
							checkOnSave = {
								command = "clippy",
							},
							cargo = {
								allFeatures = true,
							},
							procMacro = {
								enable = true,
							},
						},
					},
				},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--suggest-missing-includes",
						"--clang-tidy",
						"--header-insertion=iwyu",
					},
				},
				marksman = {},
				nil_ls = {},
				taplo = {},
				nginx_language_server = {
					cmd = { "nginx-language-server" },
					filetypes = { "nginx" },
					root_dir = function(fname)
						return lspconfig.util.root_pattern("nginx.conf", ".git")(fname)
							or lspconfig.util.path.dirname(fname)
					end,
				},
			}

			if is_executable("efm-langserver") then
				servers["efm"] = {
					filetypes = {
						"python",
						"lua",
						"sh",
						"html",
						"css",
						"javascript",
						"typescript",
						"yaml",
						"json",
						"markdown",
						"rust",
						"c",
						"cpp",
						"dockerfile",
					},
					init_options = {
						documentFormatting = true,
						documentRangeFormatting = true,
						codeAction = true,
					},
					settings = {
						rootMarkers = { ".git/", "pyproject.toml", "setup.py", "Cargo.toml", "package.json" },
					},
				}
			end

			for server_name, server_config in pairs(servers) do
				pcall(function()
					server_config.capabilities = capabilities
					lspconfig[server_name].setup(server_config)
				end)
			end
		end,
	},
}
