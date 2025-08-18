local function safe_refactor(name, refactor_func)
    return function()
        local ok, err = pcall(refactor_func)
        if not ok then
            vim.notify(name .. " failed: " .. tostring(err), vim.log.levels.ERROR)
        end
    end
end

return {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        {
            "<leader>re",
            safe_refactor("Extract Function", function() require("refactoring").refactor("Extract Function") end),
            mode = "v",
            desc = "Extract Function",
        },
        {
            "<leader>rv",
            safe_refactor("Extract Variable", function() require("refactoring").refactor("Extract Variable") end),
            mode = "v",
            desc = "Extract Variable",
        },
        {
            "<leader>rf",
            safe_refactor("Select Refactor", function() require("refactoring").select_refactor() end),
            mode = "v",
            desc = "Select Refactoring",
        },
    },
    config = function()
        require("refactoring").setup({
            print_var_statements = {
                javascript = 'console.log("%s = ", %s);',
                typescript = 'console.log("%s = ", %s);',
                lua = 'print("%s = " .. vim.inspect(%s))',
                python = 'print(f"{%s} = {%s}")',
            },
            prompt_func_return_type = {
                javascript = false,
                typescript = false,
                lua = false,
                python = false,
            },
            prompt_func_param_type = {
                javascript = false,
                typescript = false,
                lua = false,
                python = false,
            },
        })
    end,
    lazy = false,
}
