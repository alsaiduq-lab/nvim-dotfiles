return {
	{
		"smjonas/inc-rename.nvim",
		event = "LspAttach",
		config = function()
			require("inc_rename").setup({
				input_buffer_type = "dressing",
				preview_empty_name = false,
				show_message = function(msg)
					vim.notify(msg, vim.log.levels.INFO, { title = "Rename" })
				end,
			})
			vim.keymap.set("n", "<leader>rn", function()
				local curr_name = vim.fn.expand("<cword>")
				vim.ui.input({ prompt = "New name: ", default = curr_name }, function(new_name)
					if new_name then
						vim.cmd("IncRename " .. new_name)
					end
				end)
			end, { desc = "Rename with preview" })
		end,
	},
}
