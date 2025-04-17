local function safe_set(option, value)
    local success, err = pcall(function()
        vim.o[option] = value
    end)
    if not success then
        print("Failed to set " .. option .. ": " .. err)
    end
end

safe_set("number", true)
safe_set("relativenumber", true)
safe_set("mouse", "a")
safe_set("encoding", "utf-8")
safe_set("fileencoding", "utf-8")
safe_set("clipboard", "unnamedplus")
safe_set("hidden", true)
safe_set("updatetime", 300)

safe_set("syntax", "on")
safe_set("termguicolors", true)
safe_set("showmode", true)
safe_set("showcmd", true)
safe_set("showmatch", true)
safe_set("signcolumn", "yes")
safe_set("cursorline", true)
safe_set("scrolloff", 8)
safe_set("sidescrolloff", 8)

safe_set("expandtab", true)
safe_set("tabstop", 4)
safe_set("shiftwidth", 4)
safe_set("softtabstop", 4)
safe_set("autoindent", true)
safe_set("smarttab", true)
safe_set("breakindent", true)

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

-- Keymaps
local keymap = vim.keymap.set
keymap("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })
keymap("n", "<Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
keymap("n", "<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Previous buffer" })
keymap("n", "<leader>sv", ":vsplit<CR>", { silent = true, desc = "Split vertically" })
keymap("n", "<leader>sh", ":split<CR>", { silent = true, desc = "Split horizontally" })
keymap("n", "<leader>sq", ":close<CR>", { silent = true, desc = "Close window" })
keymap("n", "<C-Up>", ":resize +2<CR>", { silent = true, desc = "Increase window height" })
keymap("n", "<C-Down>", ":resize -2<CR>", { silent = true, desc = "Decrease window height" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { silent = true, desc = "Decrease window width" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { silent = true, desc = "Increase window width" })
