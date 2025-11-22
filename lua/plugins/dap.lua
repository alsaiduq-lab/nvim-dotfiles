return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-neotest/nvim-nio",
        "mfussenegger/nvim-dap-python",
        "leoluz/nvim-dap-go",
        "jbyuki/one-small-step-for-vimkind",
        "folke/noice.nvim",
        "rcarriga/nvim-notify",
        "folke/neodev.nvim",
        "mxsdev/nvim-dap-vscode-js",
        "jay-babu/mason-nvim-dap.nvim",
    },
    lazy = false,
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local notify = require("notify")

        local icons = {
            breakpoint = "●",
            breakpoint_condition = "◆",
            breakpoint_rejected = "○",
            log_point = "◉",
            stopped = "▶",
            continue = "▶",
            step_over = "↷",
            step_into = "↓",
            step_out = "↑",
            pause = "⏸",
            terminate = "■",
            repl = "»",
            ui = "☰",
            hover = "?",
        }

        local function setup_python_dap()
            local ok, python = pcall(require, "python")
            local python_path = vim.g.python3_host_prog
                or (ok and python.find_python and python.find_python())
                or "python3"
            require("dap-python").setup(python_path)
        end

        setup_python_dap()

        require("mason-nvim-dap").setup({
            automatic_installation = false,
        })

        require("dap-go").setup()

        dap.adapters.nlua = function(callback, _)
            callback({ type = "server", host = "127.0.0.1", port = 8086 })
        end

        dap.configurations.lua = {
            {
                type = "nlua",
                request = "attach",
                name = "Attach to running Neovim",
            },
        }

        vim.api.nvim_create_user_command("DapLaunchLuaServer", function()
            require("osv").launch({ port = 8086 })
        end, {})

        local js_debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
        require("dap-vscode-js").setup({
            debugger_path = js_debugger_path,
            adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
        })

        local function find_browser()
            local browsers = { "brave", "chromium", "thorium-browser", "google-chrome-stable", "chrome" }
            for _, browser in ipairs(browsers) do
                local handle = io.popen("which " .. browser .. " 2>/dev/null")
                if handle then
                    local result = handle:read("*a")
                    handle:close()
                    if result and result ~= "" then
                        return result:gsub("%s+", "")
                    end
                end
            end
            return nil
        end

        local browser_bin = find_browser()
        local debug_port = 9222

        dap.configurations.javascript = {
            {
                type = "pwa-node",
                request = "launch",
                name = "Node: Launch file",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
        }

        if browser_bin then
            table.insert(dap.configurations.javascript, {
                type = "pwa-chrome",
                request = "launch",
                name = "Browser: Launch against localhost:3000",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                runtimeExecutable = browser_bin,
                runtimeArgs = { "--remote-debugging-port=" .. debug_port },
                userDataDir = false,
            })
        end

        dap.configurations.typescript = dap.configurations.javascript
        dap.configurations.javascriptreact = dap.configurations.javascript
        dap.configurations.typescriptreact = dap.configurations.javascript

        vim.fn.sign_define("DapBreakpoint", {
            text = icons.breakpoint,
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "DapBreakpoint",
        })
        vim.fn.sign_define("DapBreakpointCondition", {
            text = icons.breakpoint_condition,
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "DapBreakpoint",
        })
        vim.fn.sign_define("DapBreakpointRejected", {
            text = icons.breakpoint_rejected,
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "DapBreakpoint",
        })
        vim.fn.sign_define("DapLogPoint", {
            text = icons.log_point,
            texthl = "DapLogPoint",
            linehl = "",
            numhl = "DapLogPoint",
        })
        vim.fn.sign_define("DapStopped", {
            text = icons.stopped,
            texthl = "DapStopped",
            linehl = "DapStoppedLine",
            numhl = "DapStopped",
        })

        dapui.setup({
            icons = { expanded = "", collapsed = "", current_frame = "" },
            controls = {
                icons = {
                    pause = icons.pause,
                    play = icons.continue,
                    step_into = icons.step_into,
                    step_over = icons.step_over,
                    step_out = icons.step_out,
                    step_back = "",
                    run_last = "",
                    terminate = icons.terminate,
                    disconnect = "",
                },
            },
        })

        require("nvim-dap-virtual-text").setup({
            virt_text_pos = "eol",
        })

        require("neodev").setup({
            library = { plugins = { "nvim-dap-ui" }, types = true },
        })

        local keymap_opts = { noremap = true, silent = true }

        vim.keymap.set("n", "<F5>", dap.continue, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Continue" }))
        vim.keymap.set("n", "<F10>", dap.step_over, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Step Over" }))
        vim.keymap.set("n", "<F11>", dap.step_into, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Step Into" }))
        vim.keymap.set("n", "<F12>", dap.step_out, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Step Out" }))

        vim.keymap.set(
            "n",
            "<leader>dp",
            dap.toggle_breakpoint,
            vim.tbl_extend("force", keymap_opts, { desc = "DAP: Toggle Breakpoint" })
        )
        vim.keymap.set("n", "<leader>dx", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Conditional Breakpoint" }))
        vim.keymap.set("n", "<leader>dl", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Log Point" }))
        vim.keymap.set(
            "n",
            "<leader>dr",
            dap.repl.toggle,
            vim.tbl_extend("force", keymap_opts, { desc = "DAP: Toggle REPL" })
        )
        vim.keymap.set(
            "n",
            "<leader>du",
            dapui.toggle,
            vim.tbl_extend("force", keymap_opts, { desc = "DAP: Toggle UI" })
        )
        vim.keymap.set("n", "<leader>de", function()
            require("dap.ui.widgets").hover()
        end, vim.tbl_extend("force", keymap_opts, { desc = "DAP: Evaluate Expression" }))
        vim.keymap.set(
            "n",
            "<leader>ds",
            dap.terminate,
            vim.tbl_extend("force", keymap_opts, { desc = "DAP: Terminate Session" })
        )

        local dap_hints = {
            "",
            "  DAP Debug Controls",
            "  ─────────────────────────────────",
            "",
            "  <F5>       " .. icons.continue .. "  Continue/Start",
            "  <F10>      " .. icons.step_over .. "  Step Over",
            "  <F11>      " .. icons.step_into .. "  Step Into",
            "  <F12>      " .. icons.step_out .. "  Step Out",
            "",
            "  <leader>dp " .. icons.breakpoint .. "  Toggle Breakpoint",
            "  <leader>dx " .. icons.breakpoint_condition .. "  Conditional Breakpoint",
            "  <leader>dl " .. icons.log_point .. "  Log Point",
            "  <leader>dr " .. icons.repl .. "  Toggle REPL",
            "  <leader>du " .. icons.ui .. "  Toggle UI",
            "  <leader>de " .. icons.hover .. "  Evaluate",
            "  <leader>ds " .. icons.terminate .. "  Terminate",
            "",
        }

        local dap_hint_buf = nil
        local dap_hint_win = nil

        local function show_dap_hints()
            if dap_hint_win and vim.api.nvim_win_is_valid(dap_hint_win) then
                vim.api.nvim_win_close(dap_hint_win, true)
            end
            if dap_hint_buf and vim.api.nvim_buf_is_valid(dap_hint_buf) then
                vim.api.nvim_buf_delete(dap_hint_buf, { force = true })
            end

            dap_hint_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(dap_hint_buf, 0, -1, false, dap_hints)
            vim.api.nvim_buf_set_option(dap_hint_buf, "modifiable", false)
            vim.api.nvim_buf_set_option(dap_hint_buf, "bufhidden", "wipe")

            local width = 42
            local height = #dap_hints

            local opts = {
                relative = "editor",
                width = width,
                height = height,
                row = 2,
                col = vim.o.columns - width - 2,
                style = "minimal",
                border = "rounded",
                zindex = 50,
                title = " DAP Hints ",
                title_pos = "center",
            }

            dap_hint_win = vim.api.nvim_open_win(dap_hint_buf, false, opts)

            vim.api.nvim_win_set_option(dap_hint_win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")

            vim.defer_fn(function()
                if dap_hint_win and vim.api.nvim_win_is_valid(dap_hint_win) then
                    vim.api.nvim_win_close(dap_hint_win, true)
                end
            end, 6000)
        end

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
            show_dap_hints()
            notify("Debug session started", "info", { title = " DAP", icon = icons.continue })
        end

        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
            if dap_hint_win and vim.api.nvim_win_is_valid(dap_hint_win) then
                vim.api.nvim_win_close(dap_hint_win, true)
            end
            notify("Debug session terminated", "warn", { title = " DAP", icon = icons.terminate })
        end

        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
            if dap_hint_win and vim.api.nvim_win_is_valid(dap_hint_win) then
                vim.api.nvim_win_close(dap_hint_win, true)
            end
            notify("Debug session exited", "warn", { title = " DAP", icon = icons.terminate })
        end

        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function(args)
                vim.keymap.set("n", "<LeftMouse>", function()
                    local mouse = vim.fn.getmousepos()
                    if mouse.winid == vim.api.nvim_get_current_win() and mouse.wincol <= 2 then
                        dap.toggle_breakpoint()
                        vim.schedule(function()
                            vim.cmd("redraw")
                        end)
                    end
                end, { buffer = args.buf, noremap = true, silent = true })
            end,
        })
    end,
}
