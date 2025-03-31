return {
	"ray-x/lsp_signature.nvim",
	event = "BufRead",
	config = function()
		require("lsp_signature").setup({
			bind = true,
			doc_lines = 15,
			max_height = 15,
			max_width = 80,
			wrap = true,
			hint_enable = true,
			hint_prefix = " ",
			hint_scheme = "String",
			hi_parameter = "Search",
			floating_window = true,
			floating_window_above_cur_line = true,
			floating_window_off_x = 1,
			fix_pos = false,
			transparency = 10,
			toggle_key = "<C-k>",
			select_signature_key = "<C-n>",
			handler_opts = {
				border = "rounded",
			},
			zindex = 200,
			shadow_blend = 36,
		})
	end,
}
