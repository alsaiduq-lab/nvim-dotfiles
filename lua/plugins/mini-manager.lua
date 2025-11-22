return {
    "echasnovski/mini.nvim",
    version = "*",
    config = function()
        local statusline = require("mini.statusline")
        statusline.setup({
            use_icons = vim.g.have_nerd_font,
            set_vim_settings = true,
            content = {
                active = function()
                    local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
                    local git = statusline.section_git({ trunc_width = 40 })
                    local diff = statusline.section_diff({ trunc_width = 75 })
                    local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
                    local lsp = statusline.section_lsp({ trunc_width = 75 })
                    local filename = statusline.section_filename({ trunc_width = 140 })
                    local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
                    local location = statusline.section_location({ trunc_width = 75 })
                    local search = statusline.section_searchcount({ trunc_width = 75 })

                    return statusline.combine_groups({
                        { hl = mode_hl, strings = { mode } },
                        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
                        "%<",
                        { hl = "MiniStatuslineFilename", strings = { filename } },
                        "%=",
                        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
                        { hl = mode_hl, strings = { search, location } },
                    })
                end,
            },
        })

        require("mini.files").setup({
            content = {
                filter = nil,
                prefix = nil,
                sort = nil,
            },
            mappings = {
                close = "q",
                go_in = "l",
                go_in_plus = "L",
                go_out = "h",
                go_out_plus = "H",
                reset = "<C-r>",
                mark_goto = "'",
                mark_set = "m",
                reveal_cwd = "@",
                show_help = "g?",
                synchronize = "=",
                trim_left = "<",
                trim_right = ">",
            },
            options = {
                permanent_delete = true,
                use_as_default_explorer = true,
            },
            windows = {
                max_number = math.huge,
                preview = true,
                width_focus = 30,
                width_nofocus = 15,
                width_preview = 50,
            },
        })

        require("mini.indentscope").setup({
            draw = {
                delay = 0,
                animation = require("mini.indentscope").gen_animation.none(),
                priority = 2,
            },
            mappings = {
                object_scope = "ii",
                object_scope_with_border = "ai",
                goto_top = "[i",
                goto_bottom = "]i",
            },
            options = {
                border = "both",
                indent_at_cursor = true,
                try_as_border = true,
            },
            symbol = "│",
        })

        require("mini.surround").setup({
            custom_surroundings = nil,
            highlight_duration = 500,
            mappings = {
                add = "sa",
                delete = "sd",
                find = "sf",
                find_left = "sF",
                highlight = "sh",
                replace = "sr",
                update_n_lines = "sn",
                suffix_last = "l",
                suffix_next = "n",
            },
            n_lines = 50,
            respect_selection_type = false,
            search_method = "cover",
            silent = false,
        })

        require("mini.pairs").setup({
            modes = { insert = true, command = false, terminal = false },
            mappings = {
                ["("] = { action = "open", pair = "()", neigh_pattern = "[^\\]." },
                ["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\]." },
                ["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\]." },
                [")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
                ["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
                ["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },
                ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\].", register = { cr = false } },
                ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\].", register = { cr = false } },
                ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].", register = { cr = false } },
            },
        })

        require("mini.ai").setup({
            custom_textobjects = nil,
            mappings = {
                around = "a",
                inside = "i",
                around_next = "an",
                inside_next = "in",
                around_last = "al",
                inside_last = "il",
                goto_left = "g[",
                goto_right = "g]",
            },
            n_lines = 500,
            search_method = "cover_or_next",
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
                fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
                todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
                note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
                hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
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
            oldfile = { suffix = "o", options = {} },
            quickfix = { suffix = "q", options = {} },
            treesitter = { suffix = "t", options = {} },
            undo = { suffix = "u", options = {} },
            window = { suffix = "w", options = {} },
            yank = { suffix = "y", options = {} },
        })

        require("mini.bufremove").setup({
            set_vim_settings = false,
            silent = false,
        })

        require("mini.trailspace").setup({
            only_in_normal_buffers = true,
        })

        require("mini.tabline").setup({
            show_icons = true,
            set_vim_settings = true,
            tabpage_section = "right",
        })

        local sessions_dir = vim.fn.stdpath("data") .. "/sessions"
        require("mini.sessions").setup({
            autoread = false,
            autowrite = true,
            directory = sessions_dir,
            file = "",
            force = { read = false, write = true, delete = false },
            hooks = {
                pre = {
                    read = nil,
                    write = function()
                        vim.cmd("silent! wall")
                    end,
                    delete = nil,
                },
                post = {
                    read = nil,
                    write = nil,
                    delete = nil,
                },
            },
            verbose = { read = false, write = false, delete = true },
        })

        require("mini.comment").setup({
            options = {
                custom_commentstring = nil,
                ignore_blank_line = false,
                start_of_line = false,
                pad_comment_parts = true,
            },
            mappings = {
                comment = "gc",
                comment_line = "gcc",
                comment_visual = "gc",
                textobject = "gc",
            },
            hooks = {
                pre = function() end,
                post = function() end,
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
