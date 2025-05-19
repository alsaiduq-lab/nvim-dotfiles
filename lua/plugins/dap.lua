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
        "stevearc/dressing.nvim",
        "folke/neodev.nvim",
        "mxsdev/nvim-dap-vscode-js",
        "jay-babu/mason-nvim-dap.nvim",
    },
    lazy = false,
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local notify = require("notify")

        require("mason-nvim-dap").setup({
            ensure_installed = {
                "python",
                "delve",
                "codelldb",
                "node2",
                "php",
                "js",
                "bash",
                "cppdbg",
                "local-lua-debugger-vscode",
            },
            automatic_installation = true,
        })

        require("dap-python").setup()
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
        local brave_bin = "/run/current-system/sw/bin/brave"
        local debug_port = 9222

        dap.configurations.javascript = {
            {
                type = "pwa-node",
                request = "launch",
                name = "Node: Launch file",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
            {
                type = "pwa-chrome",
                request = "launch",
                name = "Brave: Launch against localhost:3000",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                runtimeExecutable = brave_bin,
                runtimeArgs = { "--remote-debugging-port=" .. debug_port },
                userDataDir = false,
            },
        }
        dap.configurations.typescript = dap.configurations.javascript
        dap.configurations.javascriptreact = dap.configurations.javascript
        dap.configurations.typescriptreact = dap.configurations.javascript

        vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DapBreakpoint" })
        vim.fn.sign_define(
            "DapStopped",
            { text = "👉", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
        )

        dapui.setup()
        require("nvim-dap-virtual-text").setup()
        require("neodev").setup({
            library = { plugins = { "nvim-dap-ui" }, types = true },
        })

        vim.keymap.set("n", "<F5>", dap.continue, { desc = "Continue/Start 🟢" })
        vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step Over ⏭️" })
        vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step Into ⏬" })
        vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step Out ⏫" })

        vim.keymap.set("n", "<leader>dp", dap.toggle_breakpoint, { desc = "Toggle Breakpoint 🛑" })
        vim.keymap.set("n", "<leader>dx", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Conditional Breakpoint 🟠" })
        vim.keymap.set("n", "<leader>dl", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end, { desc = "Log Point 📄" })
        vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL 💬" })
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI Toggle 🗂️" })
        vim.keymap.set("n", "<leader>de", function()
            require("dap.ui.widgets").hover()
        end, { desc = "Eval (Hover) 🔍" })
        vim.keymap.set("n", "<leader>ds", dap.terminate, { desc = "Stop/Terminate 🛑" })

        local dap_hints = {
            "",
            "  <F5>    : Continue/Start 🟢",
            "  <F10>   : Step Over ⏭️",
            "  <F11>   : Step Into ⏬",
            "  <F12>   : Step Out ⏫",
            "",
            "  <leader>dp : Toggle Breakpoint 🛑",
            "  <leader>dx : Conditional Breakpoint 🟠",
            "  <leader>dl : Log Point 📄",
            "  <leader>dr : REPL 💬",
            "  <leader>du : UI Toggle 🗂️",
            "  <leader>de : Eval (Hover) 🔍",
            "  <leader>ds : Stop 🛑",
            "",
        }

        local dap_hint_buf = nil
        local function show_dap_hints()
            if dap_hint_buf and vim.api.nvim_buf_is_valid(dap_hint_buf) then
                vim.api.nvim_buf_delete(dap_hint_buf, { force = true })
            end
            dap_hint_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(dap_hint_buf, 0, -1, false, dap_hints)
            vim.api.nvim_buf_set_option(dap_hint_buf, "modifiable", false)
            local width = 38
            local height = #dap_hints
            local opts = {
                relative = "editor",
                width = width,
                height = height,
                row = 2,
                col = vim.o.columns - width - 2,
                style = "minimal",
                border = "rounded",
                zindex = 500,
            }
            local win = vim.api.nvim_open_win(dap_hint_buf, false, opts)
            vim.defer_fn(function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end, 6000)
        end

        dap.listeners.after.event_initialized["dapui_hints"] = function()
            dapui.open()
            show_dap_hints()
            notify("Debug session started", "info", { title = "DAP" })
        end
        dap.listeners.before.event_terminated["dapui_hints"] = function()
            dapui.close()
            if dap_hint_buf and vim.api.nvim_buf_is_valid(dap_hint_buf) then
                vim.api.nvim_buf_delete(dap_hint_buf, { force = true })
            end
            notify("Debug session terminated", "warn", { title = "DAP" })
        end
        dap.listeners.before.event_exited["dapui_hints"] = function()
            dapui.close()
            if dap_hint_buf and vim.api.nvim_buf_is_valid(dap_hint_buf) then
                vim.api.nvim_buf_delete(dap_hint_buf, { force = true })
            end
            notify("Debug session exited", "warn", { title = "DAP" })
        end

        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function(args)
                vim.keymap.set("n", "<LeftMouse>", function()
                    local mouse = vim.fn.getmousepos()
                    if mouse.winid == vim.api.nvim_get_current_win() and mouse.wincol <= 2 then
                        require("dap").toggle_breakpoint()
                        vim.schedule(function()
                            vim.cmd("redraw")
                        end)
                    end
                end, { buffer = args.buf, noremap = true, silent = true })
            end,
        })
    end,
}
