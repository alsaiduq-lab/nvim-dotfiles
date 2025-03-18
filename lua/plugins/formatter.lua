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
            logging = false,
            filetype = {
                lua = {
                    function()
                        return {
                            exe = "stylua",
                            args = {
                                "--search-parent-directories",
                                "--column-width", "120",
                                "--indent-type", "Spaces",
                                "--indent-width", "4",
                                "-",
                            },
                            stdin = true,
                        }
                    end,
                },
                python = {
                    function()
                        return {
                            exe = "ruff",
                            args = {
                                "format",
                                "--line-length", "120",
                                "--respect-gitignore",
                                "-",
                            },
                            stdin = true,
                        }
                    end,
                    function()
                        return {
                            exe = "black",
                            args = { "--quiet", "--line-length", "120", "-" },
                            stdin = true,
                        }
                    end,
                },
                javascript = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--single-quote",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                typescript = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--single-quote",
                                "--tab-width", "2",
                                "--parser", "typescript",
                            },
                            stdin = true,
                        }
                    end,
                },
                javascriptreact = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--single-quote",
                                "--tab-width", "2",
                                "--parser", "jsx",
                            },
                            stdin = true,
                        }
                    end,
                },
                typescriptreact = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--single-quote",
                                "--tab-width", "2",
                                "--parser", "tsx",
                            },
                            stdin = true,
                        }
                    end,
                },
                json = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--parser", "json",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                html = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--parser", "html",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                css = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--parser", "css",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                scss = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--parser", "scss",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                markdown = {
                    function()
                        return {
                            exe = "prettier",
                            args = {
                                "--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                                "--parser", "markdown",
                                "--prose-wrap", "always",
                                "--tab-width", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                yaml = {
                    function()
                        return {
                            exe = "yamlfmt",
                            args = {
                                "-in",
                                "-formatter",
                                "indent=2,retain_line_breaks=true",
                            },
                            stdin = true,
                        }
                    end,
                },
                rust = {
                    function()
                        return {
                            exe = "rustfmt",
                            args = {
                                "--edition", "2021",
                                "--config", "tab_spaces=4",
                            },
                            stdin = true,
                        }
                    end,
                },
                go = {
                    function()
                        return {
                            exe = "gofmt",
                            args = { "-s" },
                            stdin = true,
                        }
                    end,
                    function()
                        return {
                            exe = "goimports",
                            args = { "-w" },
                            stdin = true,
                        }
                    end,
                },
                c = {
                    function()
                        return {
                            exe = "clang-format",
                            args = {
                                "--style={BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 120}",
                            },
                            stdin = true,
                        }
                    end,
                },
                cpp = {
                    function()
                        return {
                            exe = "clang-format",
                            args = {
                                "--style={BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 120}",
                            },
                            stdin = true,
                        }
                    end,
                },
                nix = {
                    function()
                        return {
                            exe = "alejandra",
                            args = { "--quiet", "--threads", "4" },
                            stdin = true,
                        }
                    end,
                },
                sh = {
                    function()
                        return {
                            exe = "shfmt",
                            args = { "-i", "2", "-ci", "-bn" },
                            stdin = true,
                        }
                    end,
                },
                sql = {
                    function()
                        return {
                            exe = "sql-formatter",
                            args = {
                                "--language", "sql",
                                "--indent", "2",
                            },
                            stdin = true,
                        }
                    end,
                },
                ["*"] = {
                    require("formatter.filetypes.any").remove_trailing_whitespace,
                },
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
                "json", "html", "css", "scss", "yaml", "rust", "go", "nix", "c", "cpp",
                "markdown", "sh", "sql",
            }

            if not vim.tbl_contains(format_on_save_filetypes, ft) then
                return false
            end

            local win_view = vim.fn.winsaveview()
            local success, err = pcall(function()
                vim.cmd("silent! FormatWrite")
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
