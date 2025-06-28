return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost" },
    config = function()
        local lint = require("lint")
        local mason_registry = require("mason-registry")

        local all_linters_by_ft = {
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            python = { "ruff" },
            lua = { "selene" },
            markdown = { "vale" },
            css = { "stylelint" },
            html = { "htmlhint" },
            yaml = { "yamllint" },
            json = { "jsonlint" },
            dockerfile = { "hadolint" },
            sh = { "shellcheck" },
            rust = { "clippy" },
            go = { "golangci-lint" },
            ruby = { "rubocop" },
            php = { "phpcs" },
            c = { "cpplint" },
            cpp = { "cpplint" },
            java = { "checkstyle" },
            xml = { "xmllint" },
            sql = { "sqlfluff" },
            vue = { "eslint_d" },
            svelte = { "eslint_d" },
            terraform = { "tflint" },
            proto = { "buf-lint" },
            cmake = { "cmakelint" },
            dart = { "dartanalyzer" },
            kotlin = { "ktlint" },
            scala = { "scalafmt" },
            swift = { "swiftlint" },
            elixir = { "credo" },
            haskell = { "hlint" },
            r = { "lintr" },
            ocaml = { "ocamlformat" },
            nim = { "nimpretty" },
            perl = { "perlcritic" },
            powershell = { "psscriptanalyzer" },
            graphql = { "graphql-lint" },
        }

        lint.linters.ty = {
            cmd = "uvx",
            args = { "ty", "check", "--output-format", "text", "$FILENAME" },
            stdin = false,
            stream = "stdout",
            ignore_exitcode = true,
        }
        all_linters_by_ft.python[#all_linters_by_ft.python + 1] = "ty"

        local function is_linter_available(linter)
            if not lint.linters[linter] then
                return false
            end
            if mason_registry.has_package(linter) and mason_registry.is_installed(linter) then
                return true
            end
            local handle = io.popen("which " .. linter .. " 2>/dev/null")
            if handle then
                local result = handle:read("*a")
                handle:close()
                return result ~= ""
            end
            return false
        end

        lint.linters_by_ft = {}
        for ft, linters in pairs(all_linters_by_ft) do
            local available = {}
            for _, linter in ipairs(linters) do
                if is_linter_available(linter) then
                    table.insert(available, linter)
                end
            end
            if #available > 0 then
                lint.linters_by_ft[ft] = available
            end
        end

        if lint.linters.ruff and is_linter_available("ruff") then
            lint.linters.ruff.args = { "--select=ALL", "--ignore=ANN101,E501", "--no-fix", "-" }
        end
        if lint.linters.luacheck and is_linter_available("luacheck") then
            lint.linters.luacheck.args = { "--globals", "vim", "--no-max-line-length", "--no-unused-args", "-" }
        end

        local M = {
            timers = {},
            disabled_linters = {},
            debounce_ms = 1000,
        }

        local function get_available_linters(ft)
            local linters = lint.linters_by_ft[ft] or {}
            local available_linters = {}
            for _, linter in ipairs(linters) do
                if lint.linters[linter] then
                    local is_installed = false
                    if mason_registry.has_package(linter) and mason_registry.is_installed(linter) then
                        is_installed = true
                    else
                        local handle = io.popen("which " .. linter .. " 2>/dev/null")
                        if handle then
                            local result = handle:read("*a")
                            handle:close()
                            is_installed = result ~= ""
                        end
                    end
                    if is_installed then
                        table.insert(available_linters, linter)
                    end
                end
            end
            return available_linters
        end

        local function should_lint(bufnr)
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return false
            end
            local ft = vim.bo[bufnr].filetype
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if ft == "" or not lint.linters_by_ft[ft] or #lint.linters_by_ft[ft] == 0 or bufname == "" then
                return false
            end
            local byte_size = vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
            if type(byte_size) ~= "number" or byte_size > 1024 * 1024 then
                return false
            end
            if not vim.bo[bufnr].modifiable then
                return false
            end
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            if line_count <= 1 then
                local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
                if not first_line or first_line == "" then
                    return false
                end
            end
            return true
        end

        local function try_lint()
            local bufnr = vim.api.nvim_get_current_buf()
            if M.timers[bufnr] then
                M.timers[bufnr]:stop()
                M.timers[bufnr]:close()
                M.timers[bufnr] = nil
            end
            local timer = vim.loop.new_timer()
            M.timers[bufnr] = timer
            timer:start(
                M.debounce_ms,
                0,
                vim.schedule_wrap(function()
                    if not should_lint(bufnr) then
                        return
                    end
                    local ft = vim.bo[bufnr].filetype
                    local configured_linters = lint.linters_by_ft[ft] or {}
                    local active_linters = vim.tbl_filter(function(linter)
                        return not M.disabled_linters[linter]
                    end, configured_linters)
                    if #active_linters == 0 then
                        return
                    end
                    local available_linters = get_available_linters(ft)
                    local available_active_linters = vim.tbl_filter(function(linter)
                        return vim.tbl_contains(active_linters, linter)
                    end, available_linters)
                    if #available_active_linters == 0 then
                        return
                    end
                    local success, err = pcall(lint.try_lint, available_active_linters)
                    if not success then
                        vim.notify("Linting error: " .. tostring(err), vim.log.levels.ERROR)
                    end
                    if M.timers[bufnr] then
                        M.timers[bufnr]:stop()
                        M.timers[bufnr]:close()
                        M.timers[bufnr] = nil
                    end
                end)
            )
        end

        local function toggle_linter(linter_name)
            M.disabled_linters[linter_name] = not M.disabled_linters[linter_name]
            if not M.disabled_linters[linter_name] then
                try_lint()
            end
        end

        local function show_linter_status()
            local ft = vim.bo.filetype
            local configured_linters = all_linters_by_ft[ft] or {}
            if #configured_linters == 0 then
                vim.notify("No linters configured for filetype: " .. ft, vim.log.levels.INFO)
                return
            end
            local lines = {}
            table.insert(lines, "Linter status for filetype: **" .. ft .. "**")
            for _, linter in ipairs(configured_linters) do
                local enabled = (M.disabled_linters[linter] and "Disabled" or "Enabled")
                local available = is_linter_available(linter) and "Available" or "Unavailable"
                local status_icon = (enabled == "Enabled" and "" or "")
                local avail_icon = (available == "Available" and "󰄬" or "")
                table.insert(
                    lines,
                    string.format(" %s %s: %s [%s %s]", status_icon, linter, enabled, avail_icon, available)
                )
            end
            vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Linter Status" })
        end

        vim.api.nvim_create_autocmd({ "BufReadPost" }, {
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                if vim.api.nvim_buf_is_valid(bufnr) and bufname ~= "" then
                    try_lint()
                end
            end,
        })
        vim.keymap.set("n", "<leader>lt", try_lint, { desc = "󰛩  Trigger linting" })
        vim.keymap.set("n", "<leader>lc", function()
            local ft = vim.bo.filetype
            local linters = lint.linters_by_ft[ft] or {}
            if #linters == 0 then
                return
            end
            local options = {}
            for _, linter in ipairs(get_available_linters(ft)) do
                table.insert(options, { label = linter, value = linter })
            end
            vim.ui.select(options, {
                prompt = "Toggle linter for " .. ft,
                format_item = function(item)
                    return item.label
                end,
            }, function(choice)
                if choice then
                    toggle_linter(choice.value)
                end
            end)
        end, { desc = "󰒓  Toggle linters" })
        vim.keymap.set("n", "<leader>ls", show_linter_status, { desc = "󰋼  Show linter status" })
        vim.diagnostic.config({
            underline = true,
            virtual_text = true,
            signs = true,
            update_in_insert = false,
            severity_sort = true,
        }, vim.api.nvim_create_namespace("nvim_lint"))
        local signs = {
            Error = "󰅚 ",
            Warn = "󰀪 ",
            Hint = "󰌶 ",
            Info = "󰋽 ",
        }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end

        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                for bufnr, timer in pairs(M.timers) do
                    if timer then
                        timer:stop()
                        timer:close()
                        M.timers[bufnr] = nil
                    end
                end
            end,
        })
    end,
}
