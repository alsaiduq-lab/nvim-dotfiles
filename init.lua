vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("python").setup()

if vim.fn.has("win32") == 1 then
    require("hotfix").setup()
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins")
require("vim-options")
require("clipboard").setup()
