return {
    "mhartington/formatter.nvim",
    event = "BufWritePre",
    opts = {},
    config = function()
        local function notify(msg, level)
            local has_notify, nvim_notify = pcall(require, "notify")
            if has_notify then
                nvim_notify(msg, level, {
                    title = "󰁨 Auto Format",
                    timeout = 1000,
                })
            else
                print(msg)
            end
        end

        require("formatter").setup({
            logging = true,
            log_level = vim.log.levels.DEBUG, -- Temporarily set to DEBUG for more info
            filetype = {
                lua = {
                    function()
                        return {
                            exe = "stylua",
                            args = { "--search-parent-directories", "-" },
                            stdin = true,
                            try_node_modules = false, -- Disable Node.js lookup, irrelevant on Nix
                        }
                    end,
                },
                python = {
                    function()
                        return {
                            exe = "black",
                            args = { "--quiet", "--line-length", "120", "-" },
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
                rust = { require("formatter.filetypes.rust").rustfmt },
                go = { require("formatter.filetypes.go").gofmt },
                c = { require("formatter.filetypes.c").clangformat },
                cpp = { require("formatter.filetypes.cpp").clangformat },
                nix = {
                    function()
                        return {
                            exe = "alejandra",
                            args = { "--quiet" },
                            stdin = true,
                        }
                    end,
                },
                sh = { require("formatter.filetypes.sh").shfmt },
                ["*"] = { require("formatter.filetypes.any").remove_trailing_whitespace },
            },
        })

        local function format_buffer()
            local bufnr = vim.api.nvim_get_current_buf()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                notify("Invalid buffer", vim.log.levels.ERROR)
                return false
            end

            local ft = vim.bo.filetype
            if ft == "" then
                notify("No filetype detected", vim.log.levels.WARN)
                return false
            end

            local format_on_save_filetypes = {
                "lua", "python", "javascript", "typescript", "javascriptreact", "typescriptreact",
                "json", "html", "css", "scss", "yaml", "rust", "go", "nix"
            }

            if not vim.tbl_contains(format_on_save_filetypes, ft) then
                return false
            end

            local win_view = vim.fn.winsaveview()
            local success, err = pcall(function()
                vim.cmd("FormatWrite")
            end)
            vim.fn.winrestview(win_view)

            if success then
                notify("Formatted file successfully", vim.log.levels.INFO)
                return true
            else
                notify("Format failed: " .. tostring(err), vim.log.levels.ERROR)
                return false
            end
        end

        _G.format_buffer = format_buffer

        vim.keymap.set("n", "<leader>lf", function()
            format_buffer()
        end, {
            noremap = true,
            silent = true,
            desc = "󰁨 Format buffer",
        })

        vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
            callback = function()
                format_buffer()
            end,
            desc = "Auto-format on save",
        })
    end,
}
