return {
  {
    "smjonas/inc-rename.nvim",
    event = "LspAttach",
    dependencies = { "stevearc/dressing.nvim" },
    opts = {
      input_buffer_type = "dressing",
      preview_empty_name = false,
      show_message = function(msg)
        vim.notify(msg, vim.log.levels.INFO, { title = "Rename" })
      end,
    },
    keys = {
      {
        "<leader>rn",
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
            vim.notify("No LSP attached", vim.log.levels.WARN, { title = "Rename" })
            return
          end
          require("inc_rename").rename({ default = vim.fn.expand("<cword>") })
        end,
        desc = "Rename",
      },
    },
  },
}
