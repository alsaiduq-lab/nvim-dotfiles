return {
    {
        "smjonas/inc-rename.nvim",
        event = "LspAttach",
        config = function()
            require("inc_rename").setup({
                input_buffer_type = "dressing",
                preview_empty_name = false,
                rename_in_all_buffers = false,
                show_message = function(msg)
                    vim.notify(msg, vim.log.levels.INFO, { title = "Rename" })
                end,
            })
            vim.keymap.set("n", "<leader>rn", function()
                local curr_name = vim.fn.expand("<cword>")
                vim.ui.input({ prompt = "New name: ", default = curr_name }, function(new_name)
                    if new_name then
                        vim.lsp.buf.rename(new_name, {
                            filter = function()
                                return true
                            end,
                            buflnr = vim.api.nvim_get_current_buf(),
                        })
                    end
                end)
            end, { desc = "Rename with preview" })
        end,
    },
}
