-- General Settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.clipboard = "unnamedplus"
vim.opt.hidden = true
vim.opt.updatetime = 300

-- UI Settings
vim.opt.syntax = "enable"
vim.opt.termguicolors = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.showmatch = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Indentation
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0
vim.opt.softtabstop = 0
vim.opt.autoindent = true
vim.opt.smarttab = true
vim.opt.breakindent = true

-- Search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Backup and Swap
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true

-- Completion
vim.opt.completeopt = "menuone,noselect"
vim.opt.pumheight = 10

-- Window Navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })

-- Buffer Navigation
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Window Management
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split horizontally" })
vim.keymap.set("n", "<leader>sq", ":close<CR>", { desc = "Close window" })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

