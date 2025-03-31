local function safe_set(option, value)
  pcall(function() vim.o[option] = value end)
end

safe_set("number", true)
safe_set("relativenumber", true)
safe_set("mouse", "a")
safe_set("encoding", "utf-8")
safe_set("fileencoding", "utf-8")
safe_set("clipboard", "unnamedplus")
safe_set("hidden", true)
safe_set("updatetime", 300)

safe_set("syntax", "enable")
safe_set("termguicolors", true)
safe_set("showmode", true)
safe_set("showcmd", true)
safe_set("showmatch", true)
safe_set("signcolumn", "yes")
safe_set("cursorline", true)
safe_set("scrolloff", 8)
safe_set("sidescrolloff", 8)

-- Indentation
safe_set("expandtab", true)
safe_set("tabstop", 4)
safe_set("shiftwidth", 0)
safe_set("softtabstop", 0)
safe_set("autoindent", true)
safe_set("smarttab", true)
safe_set("breakindent", true)

-- Search
safe_set("hlsearch", true)
safe_set("incsearch", true)
safe_set("ignorecase", true)
safe_set("smartcase", true)

safe_set("backup", false)
safe_set("writebackup", false)
safe_set("swapfile", false)
safe_set("undofile", true)

safe_set("completeopt", "menuone,noselect")
safe_set("pumheight", 10)

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })
    vim.keymap.set("n", "<Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
    vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Previous buffer" })
    vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { silent = true, desc = "Split vertically" })
    vim.keymap.set("n", "<leader>sh", ":split<CR>", { silent = true, desc = "Split horizontally" })
    vim.keymap.set("n", "<leader>sq", ":close<CR>", { silent = true, desc = "Close window" })
    vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { silent = true, desc = "Increase window height" })
    vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { silent = true, desc = "Decrease window height" })
    vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { silent = true, desc = "Decrease window width" })
    vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { silent = true, desc = "Increase window width" })
  end,
})
