return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    config = function()
        local ufo = require("ufo")
        ufo.setup({
            open_fold_hl_timeout = 0,
            close_fold_kinds = {},
            provider_selector = function()
                return { "treesitter", "indent" }
            end,
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (" 󰁂 %d lines"):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0

                local fileSize = vim.fn.line("$")
                if fileSize > 250 and not vim.b.fold_level_set then
                    vim.opt.foldlevel = fileSize > 2000 and 0 or fileSize > 1000 and 1 or fileSize > 500 and 2 or 3
                    vim.b.fold_level_set = true
                elseif not vim.b.fold_level_set then
                    vim.opt.foldlevel = 99
                    vim.b.fold_level_set = true
                end

                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        table.insert(newVirtText, { chunkText, chunk[2] })
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end,
            preview = {
                win_config = {
                    border = "rounded",
                    winhl = "Normal:Normal",
                    winblend = 0,
                },
                mappings = {
                    scrollU = "<C-u>",
                    scrollD = "<C-d>",
                },
            },
        })

        vim.keymap.set("n", "<leader>zt", function()
            vim.opt.foldlevel = 99
            vim.b.fold_level_set = true
            ufo.openAllFolds()
        end, { desc = "Open All Folds" })

        vim.keymap.set("n", "<leader>ze", function()
            ufo.closeAllFolds()
            vim.opt.foldlevel = 0
            vim.b.fold_level_set = true
        end, { desc = "Close All Folds" })

        vim.keymap.set("n", "zK", ufo.peekFoldedLinesUnderCursor, { desc = "Peek Fold" })
    end,
}
