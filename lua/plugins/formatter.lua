---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    "mhartington/formatter.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local function notify(msg, level)
            local ok, n = pcall(require, "notify")
            if ok then
                n(msg, level, { title = "󰁨 Auto Format", timeout = 900 })
            else
                print(msg)
            end
        end

        local custom = {}
        do
            local p = vim.fn.stdpath("config") .. "/data/custom.lua"
            if vim.fn.filereadable(p) == 1 then
                local ok, mod = pcall(dofile, p)
                if ok and type(mod) == "table" then
                    custom = mod
                end
            end
        end

        local function has(bin)
            return vim.fn.executable(bin) == 1
        end
        local function fname()
            return vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))
        end

        local function fmt_cmd(exe, args, stdin)
            if not has(exe) then
                return nil
            end
            return { exe = exe, args = args or {}, stdin = stdin ~= false }
        end

        local defaults = {
            lua = {
                function()
                    return fmt_cmd("stylua", {
                        "--search-parent-directories",
                        "--column-width",
                        "120",
                        "--indent-type",
                        "Spaces",
                        "--indent-width",
                        "4",
                        "-",
                    }, true)
                end,
            },

            python = {
                function()
                    return fmt_cmd("ruff", { "format", "--line-length", "120", "--respect-gitignore", "-" }, true)
                end,
            },

            javascript = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--single-quote", "--tab-width", "2" },
                        true
                    )
                end,
            },
            typescript = {
                function()
                    return fmt_cmd("prettier", {
                        "--stdin-filepath",
                        fname(),
                        "--single-quote",
                        "--tab-width",
                        "2",
                        "--parser",
                        "typescript",
                    }, true)
                end,
            },
            javascriptreact = {
                function()
                    return fmt_cmd("prettier", {
                        "--stdin-filepath",
                        fname(),
                        "--single-quote",
                        "--tab-width",
                        "2",
                        "--parser",
                        "jsx",
                    }, true)
                end,
            },
            typescriptreact = {
                function()
                    return fmt_cmd("prettier", {
                        "--stdin-filepath",
                        fname(),
                        "--single-quote",
                        "--tab-width",
                        "2",
                        "--parser",
                        "tsx",
                    }, true)
                end,
            },

            json = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--parser", "json", "--tab-width", "2" },
                        true
                    )
                end,
            },
            jsonc = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--parser", "jsonc", "--tab-width", "2" },
                        true
                    )
                end,
            },

            html = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--parser", "html", "--tab-width", "2" },
                        true
                    )
                end,
            },
            css = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--parser", "css", "--tab-width", "2" },
                        true
                    )
                end,
            },
            scss = {
                function()
                    return fmt_cmd(
                        "prettier",
                        { "--stdin-filepath", fname(), "--parser", "scss", "--tab-width", "2" },
                        true
                    )
                end,
            },
            markdown = {
                function()
                    return fmt_cmd("prettier", {
                        "--stdin-filepath",
                        fname(),
                        "--parser",
                        "markdown",
                        "--prose-wrap",
                        "always",
                        "--tab-width",
                        "2",
                    }, true)
                end,
            },
            yaml = {
                function()
                    return fmt_cmd("yamlfmt", { "-in", "-formatter", "indent=2,retain_line_breaks=true" }, true)
                end,
            },

            rust = {
                function()
                    return fmt_cmd("rustfmt", { "--edition", "2024", "--config", "tab_spaces=4" }, true)
                end,
            },

            go = {
                function()
                    return fmt_cmd("gofumpt", {}, true)
                end,
                function()
                    return fmt_cmd("goimports", {}, true)
                end,
            },

            c = {
                function()
                    return fmt_cmd(
                        "clang-format",
                        { "--style={BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 120}" },
                        true
                    )
                end,
            },
            cpp = {
                function()
                    return fmt_cmd(
                        "clang-format",
                        { "--style={BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 120}" },
                        true
                    )
                end,
            },

            nix = {
                function()
                    return fmt_cmd("alejandra", { "--quiet", "--threads", "4" }, true)
                end,
            },

            sh = {
                function()
                    return fmt_cmd("shfmt", { "-i", "2", "-ci", "-bn" }, true)
                end,
            },

            sql = {
                function()
                    return fmt_cmd("sql-formatter", { "--language", "sql", "--indent", "2" }, true)
                end,
            },

            fish = {
                function()
                    return fmt_cmd("fish_indent", { "--write", "--no-read-stdin", fname() }, false)
                end,
            },

            nginx = {
                function()
                    return fmt_cmd("nginx-config-formatter", { "--stdin" }, true)
                end,
            },

            ["*"] = { require("formatter.filetypes.any").remove_trailing_whitespace },
        }
        local ft_map = vim.deepcopy(defaults)

        local defs = {}
        for name, def in pairs(custom.formatter_defs or {}) do
            defs[name] = function()
                if not def.exe then
                    return nil
                end
                local args = {}
                for _, a in ipairs(def.args or {}) do
                    table.insert(args, a == "$FILENAME" and fname() or a)
                end
                return fmt_cmd(def.exe, args, def.stdin ~= false)
            end
        end

        for ft, list in pairs(custom.formatters_by_ft or {}) do
            ft_map[ft] = ft_map[ft] or {}
            for _, name in ipairs(list) do
                local maker = defs[name]
                if maker then
                    table.insert(ft_map[ft], maker)
                end
            end
        end

        require("formatter").setup({
            logging = false,
            filetype = ft_map,
        })

        local function format_buffer()
            local bufnr = vim.api.nvim_get_current_buf()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                notify("Invalid buffer", vim.log.levels.ERROR)
                return false
            end
            local ft = vim.bo.filetype
            if ft == "" or not ft_map[ft] or #ft_map[ft] == 0 then
                return false
            end
            local view = vim.fn.winsaveview()
            local ok, err = pcall(function()
                vim.cmd("silent! FormatWrite")
            end)
            vim.fn.winrestview(view)
            if ok then
                notify("Formatted", vim.log.levels.INFO)
            else
                notify("Format failed: " .. tostring(err), vim.log.levels.ERROR)
            end
            return ok
        end

        vim.keymap.set("n", "<leader>F", format_buffer, { noremap = true, silent = true, desc = "󰁨 Format buffer" })

        vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
            callback = format_buffer,
            desc = "Auto-format on save",
        })
    end,
}
