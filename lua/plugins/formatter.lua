return {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local conform = require("conform")

        local function nix_cmd(exe, pkg, args)
            return {
                command = function()
                    if vim.fn.executable(exe) == 1 then
                        return exe
                    end
                    return "nix"
                end,
                args = function(self, ctx)
                    local resolved_args = {}
                    if type(args) == "function" then
                        resolved_args = args(self, ctx)
                    else
                        resolved_args = vim.deepcopy(args)
                    end

                    if vim.fn.executable(exe) == 1 then
                        return resolved_args
                    end

                    local nix_preamble = { "shell", "--quiet", "nixpkgs#" .. pkg, "-c", exe }
                    for _, v in ipairs(resolved_args) do
                        table.insert(nix_preamble, v)
                    end
                    return nix_preamble
                end,
            }
        end

        conform.setup({
            formatters = {
                ruff = nix_cmd("ruff", "ruff", {
                    "format",
                    "--line-length",
                    "120",
                    "--respect-gitignore",
                    "-",
                }),

                clang_format = nix_cmd("clang-format", "clang-tools", {
                    "--style={BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 120}",
                }),

                shfmt = nix_cmd("shfmt", "shfmt", {
                    "-i",
                    "2",
                    "-ci",
                    "-bn",
                }),

                alejandra = nix_cmd("alejandra", "alejandra", { "--quiet" }),

                nginx = nix_cmd("nginx-config-formatter", "nginx-config-formatter", { "--stdin" }),

                stylua = nix_cmd("stylua", "stylua", {
                    "--search-parent-directories",
                    "--column-width",
                    "120",
                    "--indent-type",
                    "Spaces",
                    "--indent-width",
                    "4",
                    "-",
                }),

                prettier = nix_cmd("prettier", "nodePackages.prettier", {
                    "--stdin-filepath",
                    "$FILENAME",
                    "--single-quote",
                    "--tab-width",
                    "2",
                }),

                gofumpt = nix_cmd("gofumpt", "gofumpt", {}),
                goimports = nix_cmd("goimports", "goimports", {}),
                rustfmt = nix_cmd("rustfmt", "rustfmt", { "--edition", "2021" }),
                yamlfmt = nix_cmd("yamlfmt", "yamlfmt", {
                    "-in",
                    "-formatter",
                    "indent=2,retain_line_breaks=true",
                }),
            },

            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                zsh = { "shfmt" },
                nix = { "alejandra" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                markdown = { "prettier" },
                yaml = { "yamlfmt" },
                nginx = { "nginx" },
                rust = { "rustfmt" },
                go = { "gofumpt", "goimports" },
                ["*"] = { "trim_whitespace" },
            },
            notify_on_error = false,
        })

        vim.keymap.set("n", "<leader>F", function()
            local formatters = conform.list_formatters()
            local names = vim.tbl_map(function(f)
                return f.name
            end, formatters)

            conform.format({ async = true, lsp_fallback = false, timeout_ms = 5000 }, function(err)
                if err then
                    local msg = "Format failed: " .. err
                    if #names > 0 then
                        msg = msg .. "\nAttempted: " .. table.concat(names, ", ")
                    end
                    msg = msg .. "\n\nCheck formatter installation and file syntax"
                    vim.notify(msg, vim.log.levels.ERROR)
                elseif #names > 0 then
                    vim.notify("Formatted: " .. table.concat(names, ", "), vim.log.levels.INFO)
                end
            end)
        end, { desc = "Format buffer" })

        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function(args)
                local formatters = conform.list_formatters(args.buf)
                local names = vim.tbl_map(function(f)
                    return f.name
                end, formatters)

                conform.format({ bufnr = args.buf, timeout_ms = 5000 }, function(err)
                    if err then
                        local msg = "Format failed: " .. err
                        if #names > 0 then
                            msg = msg .. "\nAttempted: " .. table.concat(names, ", ")
                        end
                        msg = msg .. "\n\nCheck formatter installation and file syntax"
                        vim.notify(msg, vim.log.levels.ERROR)
                    elseif #names > 0 then
                        vim.notify("Formatted: " .. table.concat(names, ", "), vim.log.levels.INFO)
                    end
                end)
            end,
        })
    end,
}
