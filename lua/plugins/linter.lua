return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
        local lint = require("lint")
        local function load_linter(name)
            if lint.linters[name] then
                return true
            end
            local ok, builtin = pcall(require, "lint.linters." .. name)
            if ok then
                lint.linters[name] = builtin
            end
            return ok
        end

        local function ty_parse(output, bufnr)
            local diags = {}
            local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
            for line in (output or ""):gmatch("[^\r\n]+") do
                local f, ln, col, sev, msg = line:match("^(.-):(%d+):(%d+):%s*(%a+):%s*(.*)$")
                if f and vim.fn.fnamemodify(f, ":p") == current_file then
                    local s = ({ error = 1, warning = 2, info = 3, hint = 4 })[sev:lower()] or 3
                    table.insert(diags, {
                        lnum = tonumber(ln) - 1,
                        col = tonumber(col) - 1,
                        message = msg,
                        severity = s,
                        source = "ty",
                    })
                end
            end
            return diags
        end

        local function resolve_args(args_list)
            local new_args = {}
            for _, arg in ipairs(args_list) do
                if arg == "$FILENAME" then
                    table.insert(new_args, function()
                        return vim.api.nvim_buf_get_name(0)
                    end)
                else
                    table.insert(new_args, arg)
                end
            end
            return new_args
        end

        local function get_ty_cmd()
            if vim.fn.executable("ty") == 1 then
                return "ty"
            end
            if vim.fn.executable("uvx") == 1 then
                return "uvx"
            end
            return "ty"
        end

        local function get_ty_args(base_args)
            if get_ty_cmd() == "uvx" then
                return vim.list_extend({ "ty" }, resolve_args(base_args))
            end
            return resolve_args(base_args)
        end

        local overrides = {
            ty = {
                cmd = get_ty_cmd(),
                args = get_ty_args({ "check", "--output-format", "text", "$FILENAME" }),
                parser = ty_parse,
                ignore_exitcode = true,
            },
            ruff = {
                args = {
                    "check",
                    "--select=ALL",
                    "--ignore=ANN,PGH,TCH",
                    "--quiet",
                    "--stdin-filename",
                    "$FILENAME",
                    "-",
                },
            },
            selene = {
                args = { "--display-style", "quiet", "-" },
            },
            clangtidy = {
                cmd = "clang-tidy",
                args = { "$FILENAME", "--quiet" },
                stdin = false,
            },
            cargo_clippy = {
                args = { "clippy", "--message-format", "short", "--manifest-path", "Cargo.toml" },
                stream = "stderr",
            },
        }

        for name, def in pairs(overrides) do
            load_linter(name)
            local linter = lint.linters[name] or {}
            lint.linters[name] = linter

            for key, value in pairs(def) do
                if key == "args" then
                    linter.args = resolve_args(value)
                else
                    linter[key] = value
                end
            end
        end

        lint.linters_by_ft = {
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            vue = { "eslint_d" },
            svelte = { "eslint_d" },
            css = { "stylelint" },
            html = { "htmlhint" },
            lua = { "selene" },
            python = { "ruff", "ty" },
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            zsh = { "shellcheck" },
            markdown = { "markdownlint" },
            yaml = { "yamllint" },
            json = { "jsonlint" },
            jsonc = { "biome" },
            dockerfile = { "hadolint" },
            terraform = { "tflint" },
            systemd = { "systemdlint" },
            c = { "clangtidy" },
            cpp = { "clangtidy" },
            rust = { "cargo_clippy" },
            go = { "golangcilint" },
            sql = { "sqlfluff" },
        }

        local function is_executable(linter_name)
            load_linter(linter_name)
            local linter = lint.linters[linter_name]
            if not linter then
                return false
            end

            local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
            return type(cmd) == "string" and vim.fn.executable(cmd) == 1
        end

        for ft, names in pairs(lint.linters_by_ft) do
            local available = {}
            for _, name in ipairs(names) do
                if is_executable(name) then
                    table.insert(available, name)
                end
            end
            lint.linters_by_ft[ft] = #available > 0 and available or nil
        end

        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = function()
                lint.try_lint()
            end,
        })
    end,
}
