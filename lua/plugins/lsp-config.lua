return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		priority = 100,
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "󰄬 ",
						package_pending = "󰦖 ",
						package_uninstalled = "󰰱 "
					},
					border = "rounded",
					check_outdated_packages_on_open = false
				}
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

			require("mason-tool-installer").setup({
				ensure_installed = {
					"alejandra",
					"black",
					"prettier",
					"stylua",
					"ruff",
					"clang-format",
					"shfmt",
					"sql-formatter",
					"yamlfmt",

					"eslint_d",
					"luacheck",
					"flake8",
					"markdownlint",
					"stylelint",
					"htmlhint",
					"yamllint",
					"jsonlint",
					"hadolint",
					"shellcheck",
					"cppcheck",
					"staticcheck",
					"rubocop",
					"phpcs",
					"phpstan",
					"checkstyle",
					"tflint",
					"sqlfluff",

                    "debugpy",
					"codelldb",
					"node-debug2-adapter",
					"delve",
				},
				auto_update = false,
				run_on_start = false,
				start_delay = 3000,
				debounce_hours = 24,
			})

			if not tools_installed then
				vim.defer_fn(function()
					vim.cmd("MasonToolsInstall")

					local state = io.open(state_file, "w")
					if state then
						state:write("installed")
						state:close()
					end

					vim.notify("Mason tools installation triggered", vim.log.levels.INFO, {
						title = "Mason",
						timeout = 3000,
					})
				end, 5000)
			end

			vim.api.nvim_create_user_command("MasonToolsForceInstall", function()
				vim.cmd("MasonToolsInstall")
				vim.notify("Mason tools installation forced", vim.log.levels.INFO, {
					title = "Mason",
					timeout = 2000,
				})
			end, { desc = "Force Mason tools installation" })
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
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
					"nginx_language_server",
					"nil_ls",
					"pyright",
					"ruff_lsp",
					"taplo",
					"yamlls",
				},
			})
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
				ensure_installed = {
					"python",
					"delve",
					"codelldb",
					"node2",
				},
				automatic_installation = true,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
				},
			})
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
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")
			local lspkind = require("lspkind")
			lspkind.init()
			vim.opt.signcolumn = "yes"

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
					Info = "󰋽 "
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

				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
				vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic Details" })
				vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Add Diagnostics to Location List" })
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
			setup_enhanced_diagnostics()
			vim.api.nvim_create_user_command(
				"DynamicLspLog",
				open_dynamic_lsp_log,
				{ desc = "Open dynamic LSP log in a buffer" }
			)
			vim.keymap.set("n", "<leader>dl", ":DynamicLspLog<CR>", { desc = "Open dynamic LSP log" })

			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					local opts = { buffer = event.buf }
					vim.keymap.set("n", "Ld", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "LD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "Li", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "Lo", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "Lr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "Ls", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set({ "n", "x" }, "<F3>", function()
						vim.lsp.buf.format({ async = true })
					end, opts)
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
									"describe", "it", "before_each", "after_each",
									"awesome", "client", "screen", "mouse",
									"use"
								},
								disable = {
									"missing-parameter",
									"missing-fields",
								}
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
								}
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
							schemas = require('schemastore').json.schemas(),
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
					},
				},
				ruff_lsp = {
					init_options = {
						settings = {
							args = {},
						}
					}
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
				nginx_language_server = {},
			}
			for server_name, server_config in pairs(servers) do
				server_config.capabilities = capabilities
				lspconfig[server_name].setup(server_config)
			end
		end,
	},
}
