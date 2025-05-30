local C = {}

local function has_clipboard()
    if vim.fn.has("clipboard") == 1 then
        return true
    end

    local clipboard_tools = {
        "xclip",
        "wl-copy",
        "pbcopy",
        "clip.exe",
        "termux-clipboard-set",
        "wl-paste",
        "pbpaste",
        "powershell.exe",
    }

    for _, tool in ipairs(clipboard_tools) do
        if vim.fn.executable(tool) == 1 then
            return true
        end
    end

    return false
end

function C.paste_indicator()
    return vim.o.paste and "[PASTE]" or ""
end

function C.setup_keymaps()
    local opts = { silent = true, noremap = true }

    vim.keymap.set(
        "v",
        "<leader>Cs",
        ":CopyToSystem<CR>",
        vim.tbl_extend("force", opts, { desc = "Copy to system clipboard" })
    )
    vim.keymap.set(
        "n",
        "<leader>Cp",
        ":PasteFromSystem<CR>",
        vim.tbl_extend("force", opts, { desc = "Paste from system clipboard" })
    )
    vim.keymap.set(
        "n",
        "<leader>Ca",
        ":%y+<CR>",
        vim.tbl_extend("force", opts, { desc = "Copy entire file to clipboard" })
    )

    vim.keymap.set("n", "<leader>Cf", function()
        local path = vim.fn.expand("%:p")
        vim.fn.setreg("+", path)
        vim.notify("Copied: " .. path, vim.log.levels.INFO)
    end, vim.tbl_extend("force", opts, { desc = "Copy filepath to clipboard" }))

    vim.keymap.set("n", "<leader>Cn", function()
        local filename = vim.fn.expand("%:t")
        vim.fn.setreg("+", filename)
        vim.notify("Copied: " .. filename, vim.log.levels.INFO)
    end, vim.tbl_extend("force", opts, { desc = "Copy filename to clipboard" }))

    vim.keymap.set("n", "<F3>", ":TogglePaste<CR>", vim.tbl_extend("force", opts, { desc = "Toggle paste mode" }))
end

function C.setup(opts)
    opts = opts or {}
    local silent = opts.silent or false
    local log_level = opts.log_level or vim.log.levels.INFO

    local function log(message, level)
        level = level or vim.log.levels.INFO
        if level >= log_level and not silent then
            vim.notify(message, level)
        end
    end

    local clipboard_available = has_clipboard()
    if clipboard_available then
        vim.o.clipboard = "unnamedplus"
        log("Clipboard integration enabled using system clipboard", vim.log.levels.DEBUG)
    else
        log("No clipboard provider found. Using manual clipboard commands.", vim.log.levels.WARN)
    end

    vim.api.nvim_create_user_command("CopyToSystem", function(cmdargs)
        local range = cmdargs.range or 0
        if range > 0 then
            local old_reg = vim.fn.getreg('"')
            local old_regtype = vim.fn.getregtype('"')
            vim.cmd(string.format("normal! %dGV%dGy", cmdargs.line1, cmdargs.line2))
            local content = vim.fn.getreg('"')

            if vim.fn.executable("xclip") == 1 then
                vim.fn.system("xclip -selection clipboard", content)
            elseif vim.fn.executable("wl-copy") == 1 then
                vim.fn.system("wl-copy", content)
            elseif vim.fn.executable("pbcopy") == 1 then
                vim.fn.system("pbcopy", content)
            elseif vim.fn.executable("clip.exe") == 1 then
                vim.fn.system("clip.exe", content)
            elseif vim.fn.executable("termux-clipboard-set") == 1 then
                vim.fn.system("termux-clipboard-set", content)
            end

            vim.fn.setreg('"', old_reg, old_regtype)
            log("Copied selection to system clipboard", vim.log.levels.INFO)
        else
            log("Select text first (visual mode)", vim.log.levels.ERROR)
        end
    end, { range = true, desc = "Copy to system clipboard manually" })

    vim.api.nvim_create_user_command("PasteFromSystem", function()
        local content = ""

        if vim.fn.executable("xclip") == 1 then
            content = vim.fn.system("xclip -selection clipboard -o")
        elseif vim.fn.executable("wl-paste") == 1 then
            content = vim.fn.system("wl-paste")
        elseif vim.fn.executable("pbpaste") == 1 then
            content = vim.fn.system("pbpaste")
        elseif vim.fn.executable("powershell.exe") == 1 then
            content = vim.fn.system('powershell.exe -c "Get-Clipboard"')
        elseif vim.fn.executable("termux-clipboard-get") == 1 then
            content = vim.fn.system("termux-clipboard-get")
        end

        if content and #content > 0 then
            content = content:gsub("\n$", "")
            local keys = vim.api.nvim_replace_termcodes("i" .. content .. "<ESC>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", false)
            log("Pasted from system clipboard", vim.log.levels.DEBUG)
        else
            log("No content in system clipboard or clipboard tool failed", vim.log.levels.WARN)
        end
    end, { desc = "Paste from system clipboard manually" })

    vim.api.nvim_create_user_command("TogglePaste", function()
        vim.o.paste = not vim.o.paste
        log("Paste mode " .. (vim.o.paste and "ON" or "OFF"), vim.log.levels.DEBUG)
    end, { desc = "Toggle paste mode" })

    log("Clipboard commands configured", vim.log.levels.DEBUG)
    C.setup_keymaps()
    log("Clipboard keymaps configured", vim.log.levels.DEBUG)

    return {
        clipboard_available = clipboard_available,
        log = log,
    }
end

return C
