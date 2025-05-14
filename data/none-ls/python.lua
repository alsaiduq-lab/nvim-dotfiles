return {
    filetypes = { "python" },
    actions = function(params, node, bufnr)
        local actions = {}
        if node:type() == "for_statement" then
            local for_text = vim.treesitter.get_node_text(node, bufnr)
            if for_text:match("for%s+.+:%s*\n%s*[%w_]+%.append%(") then
                table.insert(actions, {
                    title = "Convert to list comprehension",
                    action = function()
                        local list_name = for_text:match("([%w_]+)%.append")
                        local iterator = for_text:match("for%s+([%w_]+)%s+in")
                        local iterable = for_text:match("in%s+([^:]+):")
                        local expression = for_text:match("append%((.-)%)")
                        local replacement = list_name
                            .. " = ["
                            .. expression
                            .. " for "
                            .. iterator
                            .. " in "
                            .. iterable
                            .. "]"
                        local sr, sc, er, ec = node:range()
                        vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { replacement })
                    end,
                })
            end
        end
        return actions
    end,
}
