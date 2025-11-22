return {
    {
        "3rd/image.nvim",
        lazy = false,
        opts = {
            backend = "kitty",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 50,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "", "neo-tree" },
            editor_only_render_when_focused = false,
            tmux_show_only_in_active_window = false,
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
        },
    },
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "3rd/image.nvim",
        },
        config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            local config_path = vim.fn.stdpath("config") .. "/data/custom.json"
            local image_path = nil
            local use_image = false
            if vim.fn.filereadable(config_path) == 1 then
                local ok, config = pcall(function()
                    local file = io.open(config_path, "r")
                    if not file then return nil end
                    local content = file:read("*all")
                    file:close()
                    return vim.json.decode(content)
                end)
                if ok and config and config.image_path then
                    image_path = vim.fn.expand(config.image_path)
                    if vim.fn.filereadable(image_path) == 1 then
                        use_image = true
                    end
                end
            end
            dashboard.section.header.val = use_image and { "", "", "", "", "", "", "", "" } or {
                "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
                "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
                "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
                "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
                "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
            }
            dashboard.section.buttons.val = {
                dashboard.button("f", "   Find Files", ":Telescope find_files<CR>"),
                dashboard.button("r", "   Recent Files", ":Telescope oldfiles<CR>"),
                dashboard.button("g", "   Live Grep", ":Telescope live_grep<CR>"),
                dashboard.button("s", "   Git Status", ":Telescope git_status<CR>"),
                dashboard.button("c", "   Git Commits", ":Telescope git_commits<CR>"),
                dashboard.button("l", "   Lazy", ":Lazy<CR>"),
                dashboard.button("m", "   Mason", ":Mason<CR>"),
                dashboard.button("e", "   Sessions", ":lua require('mini.sessions').select()<CR>"),
                dashboard.button("q", "   Quit", ":qa<CR>"),
            }
            local function footer()
                local total_plugins = require("lazy").stats().count
                local datetime = os.date("%d-%m-%Y  %H:%M:%S")
                return datetime .. "   " .. total_plugins .. " plugins"
            end
            dashboard.section.footer.val = footer()
            dashboard.config.layout = {
                { type = "padding", val = 2 },
                dashboard.section.header,
                { type = "padding", val = 2 },
                dashboard.section.buttons,
                { type = "padding", val = 1 },
                dashboard.section.footer,
            }
            vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
            alpha.setup(dashboard.config)
            if use_image and image_path then
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = "alpha",
                    once = true,
                    callback = function()
                        vim.defer_fn(function()
                            local buf = vim.api.nvim_get_current_buf()
                            local win = vim.api.nvim_get_current_win()
                            local ok, image_api = pcall(require, "image")
                            if not ok then return end
                            local image = image_api.from_file(image_path, {
                                id = "alpha_header",
                                window = win,
                                buffer = buf,
                                with_virtual_padding = true,
                                inline = true,
                                x = 0,
                                y = 0,
                            })
                            if image then
                                image:render()
                            end
                        end, 100)
                    end,
                })
            end
        end,
    },
}
