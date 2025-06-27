

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
            local ok_mason_lsp, mason_lsp = pcall(require, "mason-lspconfig")
            local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
            if not (ok_lspconfig and ok_mason_lsp and ok_cmp) then
                return
            end
            local capabilities = cmp_nvim_lsp.default_capabilities()
            if mason_lsp.get_installed_servers then
                for _, server_name in ipairs(mason_lsp.get_installed_servers()) do
                    lspconfig[server_name].setup({
                        capabilities = capabilities,
                    })
                end
            end
            vim.keymap.set("n", "<leader>q", function()
                local diagnostics = vim.diagnostic.get(0)
                local errors, warns, infos, hints = {}, {}, {}, {}
                for _, d in ipairs(diagnostics) do
                    if d.severity == vim.diagnostic.severity.ERROR then
                        table.insert(errors, d)
                    elseif d.severity == vim.diagnostic.severity.WARN then
                        table.insert(warns, d)
                    elseif d.severity == vim.diagnostic.severity.INFO then
                        table.insert(infos, d)
                    elseif d.severity == vim.diagnostic.severity.HINT then
                        table.insert(hints, d)
                    end
                end
                local out = {}
                if next(errors) then
                    table.insert(out, "Errors:")
                    for _, d in ipairs(errors) do
                        table.insert(
                            out,
                            string.format("  [%d:%d] %s", d.lnum + 1, d.col + 1, d.message:gsub("\n", " "))
                        )
                    end
                end
                if next(warns) then
                    table.insert(out, "Warnings:")
                    for _, d in ipairs(warns) do
                        table.insert(
                            out,
                            string.format("  [%d:%d] %s", d.lnum + 1, d.col + 1, d.message:gsub("\n", " "))
                        )
                    end
                end
                if next(infos) then
                    table.insert(out, "Info:")
                    for _, d in ipairs(infos) do
                        table.insert(
                            out,
                            string.format("  [%d:%d] %s", d.lnum + 1, d.col + 1, d.message:gsub("\n", " "))
                        )
                    end
                end
                if next(hints) then
                    table.insert(out, "Hints:")
                    for _, d in ipairs(hints) do
                        table.insert(
                            out,
                            string.format("  [%d:%d] %s", d.lnum + 1, d.col + 1, d.message:gsub("\n", " "))
                        )
                    end
                end
                if #out == 0 then
                    table.insert(out, "No errors, warnings, info, or hints.")
                end
                local prev_win = vim.api.nvim_get_current_win()
                local prev_buf = vim.api.nvim_get_current_buf()
                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(bufnr, "LSP Diagnostics")
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
                vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
                vim.api.nvim_buf_set_option(bufnr, "buflisted", false)
                vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
                vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
                vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
                vim.cmd("botright split")
                local diag_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(diag_win, bufnr)
                vim.api.nvim_win_set_height(diag_win, math.max(6, #out + 2))
                vim.api.nvim_create_autocmd("WinClosed", {
                    once = true,
                    callback = function()
                        vim.schedule(function()
                            if vim.api.nvim_win_is_valid(prev_win) and vim.api.nvim_buf_is_valid(prev_buf) then
                                vim.api.nvim_set_current_win(prev_win)
                                vim.api.nvim_set_current_buf(prev_buf)
                            end
                        end)
                    end,
                })
            end, { desc = "Show LSP issues/errors" })
        end,
    },
}
