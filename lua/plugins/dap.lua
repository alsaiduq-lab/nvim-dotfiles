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
            local dap_python = require("dap-python")
            local dap_go = require("dap-go")
            local uv = vim.loop

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

            dap_python.setup()
            dap_go.setup()

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

            local function is_port_free(host, port)
                local sock = uv.new_tcp()
                local ok, err = sock:connect(host, port)
                if not ok and (err == "connection refused" or err == "timeout" or err == "host unreachable") then
                    sock:close()
                    return true
                elseif ok then
                    sock:shutdown()
                    sock:close()
                    return false
                else
                    sock:close()
                    return true
                end
            end

            local function spawn_adapter_with_retry(adapter_path, args, host, port_min, port_max, retries, on_exit)
                retries = retries or 2

                local function try_spawn()
                    local port = math.random(port_min, port_max)
                    if is_port_free(host, port) then
                        local stdout = uv.new_pipe(false)
                        local stderr = uv.new_pipe(false)
                        local handle
                        handle, _ = uv.spawn(adapter_path, {
                            args = vim.list_extend(args, { tostring(port) }),
                            stdio = { nil, stdout, stderr },
                        }, function(code)
                            stdout:close()
                            stderr:close()
                            handle:close()
                            if on_exit then
                                on_exit(code)
                            end
                        end)
                        stdout:read_start(function(err, data)
                            if err then
                                vim.schedule(function()
                                    vim.notify("[Adapter stdout error] " .. tostring(err), vim.log.levels.ERROR)
                                end)
                            end
                            if data then
                                vim.schedule(function()
                                    vim.notify("[Adapter stdout] " .. data, vim.log.levels.INFO)
                                end)
                            end
                        end)
                        stderr:read_start(function(err, data)
                            if err then
                                vim.schedule(function()
                                    vim.notify("[Adapter stderr error] " .. tostring(err), vim.log.levels.ERROR)
                                end)
                            end
                            if data then
                                vim.schedule(function()
                                    vim.notify("[Adapter stderr] " .. data, vim.log.levels.ERROR)
                                end)
                            end
                        end)
                        return port
                    else
                        return nil
                    end
                end

                local port, tries = nil, 0
                while tries < retries do
                    port = try_spawn()
                    if port then
                        return port
                    end
                    tries = tries + 1
                end
                return nil
            end

            dap.configurations.python = dap.configurations.python or {}
            local has_django = false
            local has_fastapi = false
            for _, config in ipairs(dap.configurations.python) do
                if config.name == "Django" then
                    has_django = true
                end
                if config.name == "FastAPI" then
                    has_fastapi = true
                end
            end
            if not has_django then
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Django",
                    program = "${workspaceFolder}/manage.py",
                    args = { "runserver", "--noreload" },
                    django = true,
                })
            end
            if not has_fastapi then
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "FastAPI",
                    module = "uvicorn",
                    args = { "main:app", "--reload" },
                })
            end

            dap.configurations.lua = {
                {
                    type = "nlua",
                    request = "attach",
                    name = "Attach to running Neovim instance",
                },
            }
            dap.adapters.nlua = {
                type = "executable",
                command = vim.fn.stdpath("data")
                    .. "/mason/packages/local-lua-debugger-vscode/extension/debugServer/DebugServer",
                args = {},
            }

            require("neodev").setup({
                library = { plugins = { "nvim-dap-ui" }, types = true },
            })

            local function find_free_port(min_port, max_port)
                for _ = 1, 20 do
                    local port = math.random(min_port, max_port)
                    if is_port_free("127.0.0.1", port) then
                        return port
                    end
                end
                return nil
            end

            local js_remote_debug_port = find_free_port(3400, 3499) or 9222
            local js_debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"

            require("dap-vscode-js").setup({
                debugger_path = js_debugger_path,
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
                    runtimeArgs = { "--remote-debugging-port=" .. js_remote_debug_port },
                    userDataDir = "${workspaceFolder}/.vscode/brave-debug-profile-" .. js_remote_debug_port,
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
                    runtimeArgs = { "--remote-debugging-port=" .. js_remote_debug_port },
                    userDataDir = "${workspaceFolder}/.vscode/brave-debug-profile-" .. js_remote_debug_port,
                    sourceMaps = true,
                },
            }
            dap.configurations.javascriptreact = dap.configurations.javascript
            dap.configurations.typescriptreact = dap.configurations.typescript

            dap.adapters.codelldb = function(callback)
                local adapter_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
                local port = spawn_adapter_with_retry(
                    adapter_path,
                    { "--port" },
                    "127.0.0.1",
                    3400,
                    3499,
                    10,
                    function(code)
                        if code ~= 0 then
                            vim.schedule(function()
                                vim.notify("codelldb exited with code " .. code, vim.log.levels.ERROR)
                            end)
                        end
                    end
                )
                if not port then
                    vim.notify(
                        "Failed to launch codelldb adapter: no free port found after retries",
                        vim.log.levels.ERROR
                    )
                    return
                end
                vim.defer_fn(function()
                    callback({ type = "server", host = "127.0.0.1", port = port })
                end, 500)
            end

            dap.adapters.go = function(callback)
                local dlv_path = vim.fn.exepath("dlv")
                if dlv_path == "" then
                    vim.notify("Delve not found in PATH", vim.log.levels.ERROR)
                    return
                end
                local port = spawn_adapter_with_retry(
                    dlv_path,
                    { "dap", "-l" },
                    "127.0.0.1",
                    3400,
                    3499,
                    10,
                    function(code)
                        if code ~= 0 then
                            vim.schedule(function()
                                vim.notify("delve exited with code " .. code, vim.log.levels.ERROR)
                            end)
                        end
                    end
                )
                if not port then
                    vim.notify("Failed to launch delve adapter: no free port found after retries", vim.log.levels.ERROR)
                    return
                end
                vim.defer_fn(function()
                    callback({ type = "server", host = "127.0.0.1", port = port })
                end, 500)
            end

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
                        local lines, options = {}, {}
                        for s in output:gmatch("[^\r\n]+") do
                            table.insert(lines, s)
                        end
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

            dap.adapters.php = function(callback)
                local adapter_path = vim.fn.stdpath("data")
                    .. "/mason/packages/php-debug-adapter/extension/out/phpDebug.js"
                local port = spawn_adapter_with_retry(
                    "node",
                    { adapter_path },
                    "127.0.0.1",
                    3400,
                    3499,
                    10,
                    function(code)
                        if code ~= 0 then
                            vim.schedule(function()
                                vim.notify("php-debug exited with code " .. code, vim.log.levels.ERROR)
                            end)
                        end
                    end
                )
                if not port then
                    vim.notify(
                        "Failed to launch php-debug adapter: no free port found after retries",
                        vim.log.levels.ERROR
                    )
                    return
                end
                vim.defer_fn(function()
                    callback({ type = "server", host = "127.0.0.1", port = port })
                end, 500)
            end
            dap.configurations.php = {
                {
                    type = "php",
                    request = "launch",
                    name = "Listen for Xdebug",
                    port = 9003, -- keep static
                    pathMappings = {
                        ["/var/www/html"] = "${workspaceFolder}",
                    },
                },
            }

            dap.configurations.java = {
                {
                    type = "java",
                    request = "attach",
                    name = "Debug (Attach) - Remote",
                    hostName = "127.0.0.1",
                    port = find_free_port(3400, 3499) or 5005,
                },
            }

            dap.adapters.bashdb = function(callback)
                local adapter_path = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter"
                local port = spawn_adapter_with_retry(adapter_path, {}, "127.0.0.1", 3400, 3499, 10, function(code)
                    if code ~= 0 then
                        vim.schedule(function()
                            vim.notify("bash-debug-adapter exited with code " .. code, vim.log.levels.ERROR)
                        end)
                    end
                end)
                if not port then
                    vim.notify(
                        "Failed to launch bash-debug-adapter: no free port found after retries",
                        vim.log.levels.ERROR
                    )
                    return
                end
                vim.defer_fn(function()
                    callback({ type = "server", host = "127.0.0.1", port = port })
                end, 500)
            end

            dap.configurations.sh = {
                {
                    type = "bashdb",
                    request = "launch",
                    name = "Launch Bash script",
                    showDebugOutput = true,
                    pathBashdb = vim.fn.stdpath("data")
                        .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
                    pathBashdbLib = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
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

            local function has_dap_config_for_current_ft()
                local ft = vim.bo.filetype
                return dap.configurations[ft] ~= nil and #dap.configurations[ft] > 0
            end

            local function safe_dap_call(fn)
                return function()
                    if has_dap_config_for_current_ft() then
                        fn()
                    else
                        vim.notify("No DAP configuration for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
                    end
                end
            end

            vim.keymap.set("n", "<F5>", safe_dap_call(dap.continue), { desc = "DAP Continue" })
            vim.keymap.set("n", "<F10>", safe_dap_call(dap.step_over), { desc = "DAP Step Over" })
            vim.keymap.set("n", "<F11>", safe_dap_call(dap.step_into), { desc = "DAP Step Into" })
            vim.keymap.set("n", "<F12>", safe_dap_call(dap.step_out), { desc = "DAP Step Out" })
            vim.keymap.set("n", "<leader>Db", safe_dap_call(dap.toggle_breakpoint), { desc = "Toggle Breakpoint" })
            vim.keymap.set(
                "n",
                "<leader>DB",
                safe_dap_call(function()
                    dap.set_breakpoint(vim.fn.input({ prompt = "Breakpoint condition: ", completion = "expression" }))
                end),
                { desc = "Conditional Breakpoint" }
            )
            vim.keymap.set(
                "n",
                "<leader>Dl",
                safe_dap_call(function()
                    dap.set_breakpoint(
                        nil,
                        nil,
                        vim.fn.input({ prompt = "Log point message: ", completion = "expression" })
                    )
                end),
                { desc = "Log Point" }
            )
            vim.keymap.set("n", "<leader>Dr", safe_dap_call(dap.repl.toggle), { desc = "Toggle REPL" })
            vim.keymap.set("n", "<leader>DL", safe_dap_call(dap.run_last), { desc = "Run Last" })
            vim.keymap.set(
                "n",
                "<leader>Dh",
                safe_dap_call(function()
                    require("dap.ui.widgets").hover()
                end),
                { desc = "Hover" }
            )
            vim.keymap.set(
                "n",
                "<leader>Dp",
                safe_dap_call(function()
                    require("dap.ui.widgets").preview()
                end),
                { desc = "Preview" }
            )
            vim.keymap.set(
                "n",
                "<leader>Df",
                safe_dap_call(function()
                    local widgets = require("dap.ui.widgets")
                    widgets.centered_float(widgets.frames)
                end),
                { desc = "Stack Frames" }
            )
            vim.keymap.set(
                "n",
                "<leader>Ds",
                safe_dap_call(function()
                    local widgets = require("dap.ui.widgets")
                    widgets.centered_float(widgets.scopes)
                end),
                { desc = "Scopes" }
            )
            vim.keymap.set(
                "n",
                "<leader>Du",
                safe_dap_call(function()
                    dapui.toggle()
                end),
                { desc = "Toggle DAP UI" }
            )
            vim.keymap.set(
                "n",
                "<leader>De",
                safe_dap_call(function()
                    dapui.eval()
                end),
                { desc = "Evaluate Expression" }
            )
        end)
    end,
}
