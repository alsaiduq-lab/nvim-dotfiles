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
            select_signature_key = "<C-n>",
            handler_opts = {
                border = "rounded",
            },
            zindex = 50,
            shadow_blend = 0,
        })

        vim.api.nvim_set_keymap(
            "i",
            "<C-n",
            "<cmd>lua require('lsp_signature').toggle_float_win()<CR>",
            { noremap = true, silent = true }
        )

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                require("lsp_signature").on_attach({
                    bind = true,
                    handler_opts = { border = "rounded" },
                }, args.buf)
            end,
        })
    end,
}
