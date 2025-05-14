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
        vim.schedule(function()
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
                },
                automatic_installation = true,
            })

            vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DapBreakpoint", linehl = "", numhl = "" })
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = "🔍", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
            )
            vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "DapLogPoint", linehl = "", numhl = "" })
            vim.fn.sign_define(
                "DapStopped",
                { text = "👉", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
            )

            local function notify_dap(msg, level)
                notify(msg, level, {
                    title = "Debugger",
                    icon = "🐞",
                    timeout = 2000,
                })
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "python",
                callback = function()
                    require("dap-python").setup()
                    table.insert(dap.configurations.python, {
                        type = "python",
                        request = "launch",
                        name = "Django",
                        program = "${workspaceFolder}/manage.py",
                        args = { "runserver", "--noreload" },
                        django = true,
                    })
                    table.insert(dap.configurations.python, {
                        type = "python",
                        request = "launch",
                        name = "FastAPI",
                        module = "uvicorn",
                        args = { "main:app", "--reload" },
                    })
                    notify_dap("Python debugger configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "go",
                callback = function()
                    require("dap-go").setup()
                    notify_dap("Go debugger configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "lua",
                callback = function()
                    dap.configurations.lua = {
                        {
                            type = "nlua",
                            request = "attach",
                            name = "Attach to running Neovim instance",
                        },
                    }

                    dap.adapters.nlua = function(callback, config)
                        callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
                    end
                    notify_dap("Lua debugger configured", "info")
                end,
            })

            require("neodev").setup({
                library = { plugins = { "nvim-dap-ui" }, types = true },
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
                callback = function()
                    require("dap-vscode-js").setup({
                        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
                        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
                    })

                    dap.configurations.javascript = {
                        {
                            type = "pwa-node",
                            request = "launch",
                            name = "Launch Node.js Program",
                            program = "${file}",
                            cwd = "${workspaceFolder}",
                            sourceMaps = true,
                        },
                        {
                            type = "pwa-chrome",
                            request = "launch",
                            name = "Launch Brave against localhost",
                            url = "http://localhost:3000",
                            webRoot = "${workspaceFolder}",
                            runtimeExecutable = "/usr/bin/brave-browser",
                            runtimeArgs = {
                                "--remote-debugging-port=9222",
                            },
                            userDataDir = "${workspaceFolder}/.vscode/brave-debug-profile",
                            sourceMaps = true,
                        },
                        {
                            type = "pwa-node",
                            request = "launch",
                            name = "Launch Node.js with Express",
                            program = "${workspaceFolder}/node_modules/.bin/nodemon",
                            args = { "${workspaceFolder}/app.js" },
                            cwd = "${workspaceFolder}",
                            console = "integratedTerminal",
                            internalConsoleOptions = "neverOpen",
                        },
                    }

                    dap.configurations.typescript = {
                        {
                            type = "pwa-node",
                            request = "launch",
                            name = "Launch TS Node.js Program",
                            program = "${file}",
                            runtimeExecutable = "ts-node",
                            cwd = "${workspaceFolder}",
                            sourceMaps = true,
                        },
                        {
                            type = "pwa-chrome",
                            request = "launch",
                            name = "Launch Brave against localhost",
                            url = "http://localhost:3000",
                            webRoot = "${workspaceFolder}",
                            runtimeExecutable = "/usr/bin/brave-browser",
                            runtimeArgs = {
                                "--remote-debugging-port=9222",
                            },
                            userDataDir = "${workspaceFolder}/.vscode/brave-debug-profile",
                            sourceMaps = true,
                        },
                    }

                    dap.configurations.javascriptreact = dap.configurations.javascript
                    dap.configurations.typescriptreact = dap.configurations.typescript

                    notify_dap("JavaScript/TypeScript debugger with Brave configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp", "rust" },
                callback = function()
                    dap.adapters.codelldb = {
                        type = "server",
                        port = "${port}",
                        executable = {
                            command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
                            args = { "--port", "${port}" },
                        },
                    }

                    dap.configurations.cpp = {
                        {
                            name = "Launch",
                            type = "codelldb",
                            request = "launch",
                            program = function()
                                return vim.fn.input({
                                    prompt = "Path to executable: ",
                                    default = vim.fn.getcwd() .. "/",
                                    completion = "file",
                                })
                            end,
                            cwd = "${workspaceFolder}",
                            stopOnEntry = false,
                            args = {},
                        },
                        {
                            name = "Attach to process",
                            type = "codelldb",
                            request = "attach",
                            pid = function()
                                local handle = io.popen("ps -a | grep -v grep | sort -k 1")
                                if not handle then
                                    notify_dap("Failed to list processes", "error")
                                    return nil
                                end
                                local output = handle:read("*a")
                                handle:close()
                                local lines = {}
                                for s in output:gmatch("[^\r\n]+") do
                                    table.insert(lines, s)
                                end
                                local options = {}
                                for _, line in ipairs(lines) do
                                    local pid = line:match("^%s*(%d+)")
                                    if pid then
                                        table.insert(options, pid .. ": " .. line)
                                    end
                                end
                                if #options == 0 then
                                    notify_dap("No processes found", "error")
                                    return nil
                                end
                                local choices = vim.list_extend({ "Select process to attach to:" }, options)
                                local choice = vim.fn.inputlist(choices)
                                if choice < 1 or choice > #options or not options[choice] then
                                    return nil
                                end
                                local pid = options[choice]:match("^%s*(%d+)")
                                return pid and tonumber(pid) or nil
                            end,
                            args = {},
                        },
                    }

                    dap.configurations.c = dap.configurations.cpp
                    dap.configurations.rust = dap.configurations.cpp
                    notify_dap("C/C++/Rust debugger configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "php",
                callback = function()
                    dap.adapters.php = {
                        type = "executable",
                        command = "node",
                        args = {
                            vim.fn.stdpath("data") .. "/mason/packages/php-debug-adapter/extension/out/phpDebug.js",
                        },
                    }

                    dap.configurations.php = {
                        {
                            type = "php",
                            request = "launch",
                            name = "Listen for Xdebug",
                            port = 9003,
                            pathMappings = {
                                ["/var/www/html"] = "${workspaceFolder}",
                            },
                        },
                    }
                    notify_dap("PHP debugger configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function()
                    dap.configurations.java = {
                        {
                            type = "java",
                            request = "attach",
                            name = "Debug (Attach) - Remote",
                            hostName = "127.0.0.1",
                            port = 5005,
                        },
                    }
                    notify_dap("Java debugger configured", "info")
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sh", "bash", "zsh" },
                callback = function()
                    dap.adapters.bashdb = {
                        type = "executable",
                        command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
                        name = "bashdb",
                    }

                    dap.configurations.sh = {
                        {
                            type = "bashdb",
                            request = "launch",
                            name = "Launch Bash script",
                            showDebugOutput = true,
                            pathBashdb = vim.fn.stdpath("data")
                                .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
                            pathBashdbLib = vim.fn.stdpath("data")
                                .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
                            trace = true,
                            file = "${file}",
                            program = "${file}",
                            cwd = "${workspaceFolder}",
                            pathCat = "cat",
                            pathBash = "/bin/bash",
                            pathMkfifo = "mkfifo",
                            pathPkill = "pkill",
                            args = {},
                            env = {},
                            terminalKind = "integrated",
                        },
                    }
                    notify_dap("Shell script debugger configured", "info")
                end,
            })

            dapui.setup({
                icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
                mappings = {
                    expand = { "<CR>", "<2-LeftMouse>" },
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                },
                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.25 },
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks", size = 0.25 },
                            { id = "watches", size = 0.25 },
                        },
                        position = "left",
                        size = 40,
                    },
                    {
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                        position = "bottom",
                        size = 10,
                    },
                },
                floating = {
                    max_height = nil,
                    max_width = nil,
                    border = "single",
                    mappings = {
                        close = { "q", "<Esc>" },
                    },
                },
                windows = { indent = 1 },
                render = {
                    max_type_length = nil,
                    max_value_lines = 100,
                },
            })

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
                notify_dap("Debug session started", "info")
            end

            dap.listeners.before.event_terminated["dapui_config"] = function()
                notify_dap("Debug session terminated", "warn")
                dapui.close()
            end

            dap.listeners.before.event_exited["dapui_config"] = function()
                notify_dap("Debug session exited", "warn")
                dapui.close()
            end

            require("nvim-dap-virtual-text").setup({
                enabled = true,
                enabled_commands = true,
                highlight_changed_variables = true,
                highlight_new_as_changed = true,
                show_stop_reason = true,
                commented = false,
                virt_text_pos = "eol",
                all_frames = false,
                virt_lines = false,
                virt_text_win_col = nil,
            })

            vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
            vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
            vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
            vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
            vim.keymap.set("n", "<leader>Db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
            vim.keymap.set("n", "<leader>DB", function()
                dap.set_breakpoint(vim.fn.input({
                    prompt = "Breakpoint condition: ",
                    completion = "expression",
                }))
            end, { desc = "Conditional Breakpoint" })
            vim.keymap.set("n", "<leader>Dl", function()
                dap.set_breakpoint(
                    nil,
                    nil,
                    vim.fn.input({
                        prompt = "Log point message: ",
                        completion = "expression",
                    })
                )
            end, { desc = "Log Point" })
            vim.keymap.set("n", "<leader>Dr", dap.repl.toggle, { desc = "Toggle REPL" })
            vim.keymap.set("n", "<leader>DL", dap.run_last, { desc = "Run Last" })
            vim.keymap.set("n", "<leader>Dh", function()
                require("dap.ui.widgets").hover()
                notify_dap("Showing debug info", "info")
            end, { desc = "Hover" })
            vim.keymap.set("n", "<leader>Dp", function()
                require("dap.ui.widgets").preview()
            end, { desc = "Preview" })
            vim.keymap.set("n", "<leader>Df", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.frames)
            end, { desc = "Stack Frames" })
            vim.keymap.set("n", "<leader>Ds", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.scopes)
            end, { desc = "Scopes" })
            vim.keymap.set("n", "<leader>Du", function()
                dapui.toggle()
            end, { desc = "Toggle DAP UI" })
            vim.keymap.set("n", "<leader>De", function()
                dapui.eval()
            end, { desc = "Evaluate Expression" })
        end)
    end,
}
