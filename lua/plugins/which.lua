return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    config = function()
        local wk = require("which-key")
        wk.setup({
            plugins = {
                marks = true,
                registers = true,
                spelling = { enabled = true, suggestions = 20 },
                presets = {
                    operators = true,
                    motions = true,
                    text_objects = true,
                    windows = true,
                    nav = true,
                    z = true,
                    g = true,
                },
            },
            icons = { breadcrumb = "»", separator = "➜", group = "+" },
            popup = {
                border = "rounded",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 1, 1, 1, 1 },
                winblend = 0,
            },
            layout = {
                height = { min = 4, max = 25 },
                width = { min = 20, max = 50 },
                spacing = 3,
                align = "left",
            },
            show_help = true,
            show_keys = true,
            triggers = { "<leader>" },
            delay = 0,
        })

        local function infer_desc(rhs)
            if not rhs or rhs == "" then
                return nil
            end
            rhs = rhs:gsub("^<cmd>", ""):gsub("^:", ""):gsub("<CR>$", ""):gsub("%s+$", "")
            rhs = rhs:gsub("^Telescope%s+", "Telescope ")
            rhs = rhs:gsub("^Neotree%s+", "Neo-tree ")
            rhs = rhs:gsub("^Lazy$", "Lazy")
            rhs = rhs:gsub("^Mason$", "Mason")
            return rhs
        end

        local function annotate_mode(mode)
            local leader = vim.g.mapleader or "\\"
            local specs = {}
            for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
                local lhs = m.lhs or ""
                if lhs:sub(1, #leader) == leader then
                    local desc = m.desc or infer_desc(m.rhs)
                    if desc and desc ~= "" then
                        table.insert(specs, { lhs, desc = desc, mode = mode })
                    end
                end
            end
            if #specs > 0 then
                if wk.add then
                    wk.add(specs)
                else
                    local reg = {}
                    for _, s in ipairs(specs) do
                        reg[s[1]] = { function() end, s.desc }
                    end
                    wk.register(reg, { mode = mode })
                end
            end
        end

        for _, mode in ipairs({ "n", "v", "x", "o" }) do
            annotate_mode(mode)
        end
    end,
}
