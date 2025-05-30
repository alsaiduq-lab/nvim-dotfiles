return {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 1000,
    config = function()
        local notify = require("notify")
        notify.setup({
            background_colour = "#1a1b26",
            timeout = 3000,
            max_width = 60,
            render = "wrapped-default",
            stages = "fade",
            on_open = function(win)
                vim.api.nvim_win_set_option(win, "wrap", true)
                vim.api.nvim_win_set_config(win, { border = "rounded" })
            end,
        })
        vim.notify = notify
        vim.cmd([[
      highlight NotifyERRORBorder guifg=#db4b4b guibg=NONE
      highlight NotifyWARNBorder guifg=#e0af68 guibg=NONE
      highlight NotifyINFOBorder guifg=#0db9d7 guibg=NONE
      highlight NotifyDEBUGBorder guifg=#9d7cd8 guibg=NONE
      highlight NotifyTRACEBorder guifg=#bb9af7 guibg=NONE
      highlight NotifyERRORIcon guifg=#ff0055 guibg=NONE
      highlight NotifyWARNIcon guifg=#ffb86c guibg=NONE
      highlight NotifyINFOIcon guifg=#7dcfff guibg=NONE
      highlight NotifyDEBUGIcon guifg=#9d7cd8 guibg=NONE
      highlight NotifyTRACEIcon guifg=#bb9af7 guibg=NONE
      highlight NotifyERRORTitle guifg=#ff0055 guibg=NONE gui=bold
      highlight NotifyWARNTitle guifg=#ffb86c guibg=NONE gui=bold
      highlight NotifyINFOTitle guifg=#7dcfff guibg=NONE gui=bold
      highlight NotifyDEBUGTitle guifg=#9d7cd8 guibg=NONE gui=bold
      highlight NotifyTRACETitle guifg=#bb9af7 guibg=NONE gui=bold
      highlight NotifyERRORBody guibg=NONE guifg=#c0caf5
      highlight NotifyWARNBody guibg=NONE guifg=#c0caf5
      highlight NotifyINFOBody guibg=NONE guifg=#c0caf5
      highlight NotifyDEBUGBody guibg=NONE guifg=#c0caf5
      highlight NotifyTRACEBody guibg=NONE guifg=#c0caf5
]])
    end,
}
