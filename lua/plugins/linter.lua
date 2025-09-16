return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
        local lint = require("lint")

        local custom = {}
        local path = vim.fn.stdpath("config") .. "/data/custom.lua"
        if vim.fn.filereadable(path) == 1 then
            local ok, mod = pcall(dofile, path)
            if ok and type(mod) == "table" then
                custom = mod
            end
        end

        local function resolve_cmd(cmd)
            if cmd == "AUTO_TY_CHECK" then
                if vim.fn.executable("ty") == 1 then
                    return "ty", { "check" }
                end
                if vim.fn.executable("uvx") == 1 then
                    return "uvx", { "ty", "check" }
                end
                return "ty", { "check" }
            end
            return cmd, nil
        end

        local function ty_parse(output, bufnr)
            local diags, here = {}, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
            for line in (output or ""):gmatch("[^\r\n]+") do
                local f, ln, col, sev, msg = line:match("^(.-):(%d+):(%d+):%s*(%a+):%s*(.*)$")
                if f and ln and col and sev and msg and vim.fn.fnamemodify(f, ":p") == here then
                    local s = ({ error = 1, warning = 2, info = 3, information = 3, hint = 4 })[sev:lower()] or 3
                    diags[#diags + 1] =
                        { lnum = tonumber(ln) - 1, col = tonumber(col) - 1, message = msg, severity = s, source = "ty" }
                end
            end
            return diags
        end

        for name, def in pairs(custom.linter_defs or {}) do
            local cmd, pre = def.cmd, nil
            if type(cmd) == "string" then
                cmd, pre = resolve_cmd(cmd)
            end
            local args = {}
            if pre then
                vim.list_extend(args, pre)
            end
            for _, a in ipairs(def.args or {}) do
                if a == "$FILENAME" then
                    args[#args + 1] = function(ctx)
                        return ctx.filename
                    end
                else
                    args[#args + 1] = a
                end
            end
            lint.linters[name] = {
                cmd = cmd,
                args = args,
                stdin = def.stdin or false,
                stream = def.stream or "stdout",
                ignore_exitcode = (def.ignore_exitcode ~= false),
                parser = (def.parser == "ty_text") and ty_parse or def.parser,
            }
        end

        local merged = vim.deepcopy(custom.linters_by_ft or {})

        local function ensure_builtin(name)
            if lint.linters[name] then
                return true
            end
            local ok = pcall(function()
                lint.linters[name] = require("lint.linters." .. name)
            end)
            return ok and lint.linters[name] ~= nil
        end

        local function linter_is_available(name)
            if not (lint.linters[name] or ensure_builtin(name)) then
                return false
            end
            local cmd = lint.linters[name].cmd
            if type(cmd) == "table" then
                cmd = cmd[1]
            end
            return type(cmd) == "string" and vim.fn.executable(cmd) == 1
        end
        lint.linters_by_ft = {}
        for ft, names in pairs(merged) do
            local avail = {}
            for _, n in ipairs(names) do
                if linter_is_available(n) then
                    avail[#avail + 1] = n
                end
            end
            if #avail > 0 then
                lint.linters_by_ft[ft] = avail
            end
        end
        local M = { timers = {}, ms = 600 }
        local function ok_buf(buf)
            return vim.api.nvim_buf_is_valid(buf)
                and vim.bo[buf].modifiable
                and vim.bo[buf].filetype ~= ""
                and lint.linters_by_ft[vim.bo[buf].filetype] ~= nil
        end
        local function run(buf)
            if not ok_buf(buf) then
                return
            end
            pcall(lint.try_lint, lint.linters_by_ft[vim.bo[buf].filetype])
        end
        local function debounced()
            local b = vim.api.nvim_get_current_buf()
            if M.timers[b] then
                pcall(vim.fn.timer_stop, M.timers[b])
                M.timers[b] = nil
            end
            M.timers[b] = vim.fn.timer_start(M.ms, function()
                run(b)
                M.timers[b] = nil
            end)
        end
        vim.api.nvim_create_autocmd(
            { "BufReadPost", "BufNewFile", "BufWritePost", "InsertLeave", "TextChanged" },
            { callback = debounced }
        )
    end,
}
