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
                    opts = {},
                    format = {
                        cmdline = { pattern = "^:", icon = "", lang = "vim" },
                        search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
                        search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
                        filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                        lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                        help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
                    },
                },
                messages = {
                    enabled = true,
                    view = "notify",
                    view_error = "notify",
                    view_warn = "notify",
                    view_history = "messages",
                    view_search = "virtualtext",
                },
                popupmenu = {
                    enabled = true,
                    backend = "nui",
                },
                lsp = {
                    progress = {
                        enabled = true,
                        format = "lsp_progress",
                        format_done = "lsp_progress_done",
                        throttle = 1000 / 30,
                        view = "mini",
                    },
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                    hover = {
                        enabled = true,
                        silent = false,
                        view = nil,
                        opts = {},
                    },
                    signature = {
                        enabled = true,
                        auto_open = {
                            enabled = true,
                            trigger = true,
                            luasnip = true,
                            throttle = 50,
                        },
                        view = nil,
                        opts = {},
                    },
                    message = {
                        enabled = true,
                        view = "notify",
                        opts = {},
                    },
                    documentation = {
                        view = "hover",
                        opts = {
                            lang = "markdown",
                            replace = true,
                            render = "plain",
                            format = { "{message}" },
                            win_options = { concealcursor = "n", conceallevel = 3 },
                        },
                    },
                },
                routes = {
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "written",
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "more lines",
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "fewer lines",
                        },
                        opts = { skip = true },
                    },
                },
                views = {
                    cmdline_popup = {
                        position = {
                            row = "40%",
                            col = "50%",
                        },
                        size = {
                            width = 60,
                            height = "auto",
                        },
                        border = {
                            style = "rounded",
                            padding = { 0, 1 },
                        },
                        win_options = {
                            winhighlight = {
                                Normal = "Normal",
                                FloatBorder = "DiagnosticInfo",
                            },
                        },
                    },
                    popupmenu = {
                        relative = "editor",
                        position = {
                            row = 8,
                            col = "50%",
                        },
                        size = {
                            width = 60,
                            height = 10,
                        },
                        border = {
                            style = "rounded",
                            padding = { 0, 1 },
                        },
                        win_options = {
                            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
                        },
                    },
                },
                presets = {
                    bottom_search = false,
                    command_palette = true,
                    long_message_to_split = true,
                    inc_rename = false,
                    lsp_doc_border = true,
                },
            })
        end,
    },
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        opts = {
            input = {
                enabled = true,
                default_prompt = "Input",
                trim_prompt = true,
                title_pos = "left",
                insert_only = true,
                start_in_insert = true,
                border = "rounded",
                relative = "cursor",
                prefer_width = 40,
                width = nil,
                max_width = { 140, 0.9 },
                min_width = { 20, 0.2 },
                buf_options = {},
                win_options = {
                    wrap = false,
                    list = true,
                    listchars = "precedes:…,extends:…",
                    sidescrolloff = 0,
                },
                mappings = {
                    n = {
                        ["<Esc>"] = "Close",
                        ["<CR>"] = "Confirm",
                    },
                    i = {
                        ["<C-c>"] = "Close",
                        ["<CR>"] = "Confirm",
                        ["<Up>"] = "HistoryPrev",
                        ["<Down>"] = "HistoryNext",
                    },
                },
                override = function(conf)
                    return conf
                end,
                get_config = nil,
            },
            select = {
                enabled = true,
                backend = { "telescope", "builtin", "nui" },
                trim_prompt = true,
                telescope = require("telescope.themes").get_dropdown({
                    borderchars = {
                        { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                        prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
                        results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
                        preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                    },
                    width = 0.8,
                    previewer = false,
                    prompt_title = false,
                }),
                builtin = {
                    show_numbers = true,
                    border = "rounded",
                    relative = "editor",
                    buf_options = {},
                    win_options = {
                        cursorline = true,
                        cursorlineopt = "both",
                    },
                    width = nil,
                    max_width = { 140, 0.8 },
                    min_width = { 40, 0.2 },
                    height = nil,
                    max_height = 0.9,
                    min_height = { 10, 0.2 },
                    mappings = {
                        ["<Esc>"] = "Close",
                        ["<C-c>"] = "Close",
                        ["<CR>"] = "Confirm",
                    },
                    override = function(conf)
                        return conf
                    end,
                },
                format_item_override = {},
                get_config = nil,
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
            vim.o.winwidth = 10
            vim.o.winminwidth = 10
            vim.o.equalalways = false
            require("windows").setup({
                autowidth = {
                    enable = true,
                    winwidth = 5,
                    filetype = {
                        help = 2,
                    },
                },
                ignore = {
                    buftype = { "quickfix" },
                    filetype = { "NvimTree", "neo-tree", "undotree", "gundo" },
                },
                animation = {
                    enable = true,
                    duration = 150,
                    fps = 30,
                    easing = "in_out_sine",
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
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false

                local opts = { silent = true, buffer = bufnr }
                vim.keymap.set("n", "Gs", "<cmd>TSToolsOrganizeImports<CR>", opts)
                vim.keymap.set("n", "Gi", "<cmd>TSToolsRenameFile<CR>", opts)
                vim.keymap.set("n", "Go", "<cmd>TSToolsAddMissingImports<CR>", opts)
                vim.keymap.set("n", "Gu", "<cmd>TSToolsRemoveUnusedImports<CR>", opts)
                vim.keymap.set("n", "Gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "Gk", vim.lsp.buf.hover, opts)
                vim.keymap.set("n", "Gr", vim.lsp.buf.references, opts)
            end,
            settings = {
                separate_diagnostic_server = true,
                publish_diagnostic_on = "insert_leave",
                expose_as_code_action = "all",
                tsserver_path = nil,
                tsserver_plugins = {},
                tsserver_max_memory = "auto",
                tsserver_format_options = {},
                tsserver_file_preferences = {
                    includeInlayParameterNameHints = "all",
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                    importModuleSpecifierPreference = "non-relative",
                    quotePreference = "auto",
                },
                tsserver_locale = "en",
                complete_function_calls = false,
                include_completions_with_insert_text = true,
                code_lens = "off",
                disable_member_code_lens = true,
                jsx_close_tag = {
                    enable = false,
                    filetypes = { "javascriptreact", "typescriptreact" },
                },
            },
        },
    },
}
