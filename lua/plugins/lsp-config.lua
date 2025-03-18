return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "󰄬 ",
						package_pending = "󰦖 ",
						package_uninstalled = "󰚌 "
					},
					border = "rounded"
				}
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"alejandra",  -- Nix formatter
					"black",      -- Python formatter
					"prettier",   -- Web formatting
					"eslint_d",   -- JavaScript/TypeScript linter (daemon)
					"mypy",       -- Python type checker
					"shellcheck", -- Shell script analysis
					"ts-standard" -- TypeScript standard style
				},
				auto_update = true,
				run_on_start = true,
			})
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
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
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
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
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
