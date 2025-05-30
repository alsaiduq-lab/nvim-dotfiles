return {
    "vyfor/cord.nvim",
    build = ":Cord update",
    config = function()
        require("cord").setup({
            enabled = true,
            debug = true,
            log_level = vim.log.levels.OFF,
            display = {
                theme = "catppuccin",
                flavor = "accent",
            },
            buttons = {
                {
                    label = function(opts)
                        if opts.repo_url and opts.repo_url:match("^https://github.com/") then
                            return "guthib repo"
                        end
                        return "guthib profile"
                    end,
                    url = function(opts)
                        if opts.repo_url and opts.repo_url:match("^https://github.com/") then
                            return opts.repo_url
                        end
                        return "https://github.com/alsaiduq-lab"
                    end,
                },
                {
                    label = "Countdown to leave Windows 10",
                    url = "https://monaie.ca/windows10-eos",
                },
            },
            hooks = {
                workspace_change = function(opts)
                    opts.manager:queue_update(true)
                end,
            },
        })
    end,
}
