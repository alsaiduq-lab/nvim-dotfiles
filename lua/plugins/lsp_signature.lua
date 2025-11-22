return {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = function()
        require("lsp_signature").setup({
            bind = true,
            doc_lines = 10,
            max_height = 12,
            max_width = 60,
            wrap = true,
            hint_enable = true,
            hint_prefix = " ",
            hint_scheme = "String",
            hi_parameter = "Search",
            floating_window = true,
            floating_window_above_cur_line = false,
            floating_window_off_x = 0,
            floating_window_off_y = 1,
            fix_pos = false,
            transparency = 0,
            handler_opts = {
                border = "rounded",
            },
            zindex = 50,
            shadow_blend = 0,
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local bufnr = args.buf
                vim.keymap.set("i", "<C-l>", function()
                    vim.lsp.buf.signature_help()
                end, { buffer = bufnr, noremap = true, silent = true, desc = "Signature help" })
            end,
        })
    end,
}
