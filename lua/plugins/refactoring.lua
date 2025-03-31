return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{
			"<leader>re",
			function()
				local ok, err = pcall(function()
					require("refactoring").refactor("Extract Function")
				end)
				if not ok then
					vim.notify("Extract Function failed: " .. err, vim.log.levels.ERROR)
				end
			end,
			mode = "v",
			desc = "Extract Function",
		},
		{
			"<leader>rv",
			function()
				local ok, err = pcall(function()
					require("refactoring").refactor("Extract Variable")
				end)
				if not ok then
					vim.notify("Extract Variable failed: " .. err, vim.log.levels.ERROR)
				end
			end,
			mode = "v",
			desc = "Extract Variable",
		},
		{
			"<leader>rf",
			function()
				local ok, err = pcall(function()
					require("refactoring").select_refactor()
				end)
				if not ok then
					vim.notify("Select Refactor failed: " .. err, vim.log.levels.ERROR)
				end
			end,
			mode = "v",
			desc = "Select Refactoring",
		},
	},
	config = function()
		require("refactoring").setup({
			print_var_statements = {
				javascript = 'console.log(" %s = ", %s);',
				typescript = 'console.log(" %s = ", %s);',
				lua = 'print("%s = " .. vim.inspect(%s))',
				python = 'print(f"{ %s } = { %s }")',
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
