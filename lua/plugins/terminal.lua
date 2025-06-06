return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        local status_ok, toggleterm = pcall(require, "toggleterm")
        if not status_ok then
            return
        end

        toggleterm.setup({
            size = 20,
            open_mapping = [[<c-\>]],
            shade_filetypes = {},
            shade_terminals = true,
            shading_factor = 1,
            start_in_insert = true,
            insert_mappings = true,
            terminal_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "single",
                width = function()
                    return math.floor(vim.o.columns * 0.85)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.85)
                end,
                winblend = 0,
                title = "Terminal",
                title_pos = "center",
            },
            winbar = {
                enabled = true,
                name_formatter = function(term)
                    if not term.name or term.name == "" or term.name:match("^ToggleTerm") then
                        return "Terminal"
                    end
                    return term.name
                end,
            },
            highlights = {
                NormalFloat = { link = "Normal" },
                FloatBorder = { link = "FloatBorder" },
            },
        })

        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
            cmd = "lazygit",
            hidden = true,
            direction = "float",
            name = "Lazygit",
            float_opts = {
                border = "single",
                width = function()
                    return math.floor(vim.o.columns * 0.9)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.9)
                end,
                title = "Lazygit",
                title_pos = "center",
            },
        })

        local function _LAZYGIT_TOGGLE()
            lazygit:toggle()
        end

        local lazydocker = Terminal:new({
            cmd = "lazydocker",
            hidden = true,
            direction = "float",
            name = "Lazydocker",
            float_opts = {
                border = "single",
                width = function()
                    return math.floor(vim.o.columns * 0.9)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.9)
                end,
                title = "Lazydocker",
                title_pos = "center",
            },
        })

        local function _LAZYDOCKER_TOGGLE()
            lazydocker:toggle()
        end

        local function set_terminal_keymaps()
            local opts = { buffer = 0 }
            vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
            vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
            vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
            vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
            vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
        end

        vim.api.nvim_create_autocmd("TermOpen", {
            pattern = "term://*",
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local name = vim.api.nvim_buf_get_name(bufnr)
                if name:match("term://") and name:match("ToggleTerm") then
                    vim.api.nvim_buf_set_name(bufnr, "Terminal")
                end
                set_terminal_keymaps()
            end,
        })

        local opts = { noremap = true, silent = true }
        vim.keymap.set(
            "n",
            "<leader>tt",
            ":ToggleTerm direction=float<CR>",
            vim.tbl_extend("force", opts, { desc = "Toggle Terminal" })
        )
        vim.keymap.set("n", "<leader>tg", function()
            _LAZYGIT_TOGGLE()
        end, vim.tbl_extend("force", opts, { desc = "Toggle Lazygit" }))

        vim.keymap.set("n", "<leader>td", function()
            _LAZYDOCKER_TOGGLE()
        end, vim.tbl_extend("force", opts, { desc = "󰡨 Toggle Lazydocker" }))
    end,
}
