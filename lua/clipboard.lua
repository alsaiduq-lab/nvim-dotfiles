local C = {}

local function has_clipboard()
    if vim.fn.has("clipboard") == 1 then
        return true
    end
    for _, tool in ipairs({
        "xclip",
        "wl-copy",
        "wl-paste",
        "pbcopy",
        "pbpaste",
        "clip.exe",
        "powershell.exe",
        "termux-clipboard-set",
        "termux-clipboard-get",
    }) do
        if vim.fn.executable(tool) == 1 then
            return true
        end
    end
    return false
end

local function system_clipboard()
    local exec = vim.fn.executable
    if exec("wl-paste") == 1 then
        return vim.fn.system("wl-paste --no-newline")
    elseif exec("xclip") == 1 then
        return vim.fn.system("xclip -selection clipboard -o")
    elseif exec("pbpaste") == 1 then
        return vim.fn.system("pbpaste")
    elseif exec("powershell.exe") == 1 then
        return vim.fn.system([[powershell.exe -c "Get-Clipboard"]])
    elseif exec("termux-clipboard-get") == 1 then
        return vim.fn.system("termux-clipboard-get")
    end
    return ""
end

local function system_copy(content)
    local exec = vim.fn.executable
    if exec("wl-copy") == 1 then
        vim.fn.system("wl-copy", content)
    elseif exec("xclip") == 1 then
        vim.fn.system("xclip -selection clipboard", content)
    elseif exec("pbcopy") == 1 then
        vim.fn.system("pbcopy", content)
    elseif exec("clip.exe") == 1 then
        vim.fn.system("clip.exe", content)
    elseif exec("termux-clipboard-set") == 1 then
        vim.fn.system("termux-clipboard-set", content)
    end
end

local function paste()
    local content = system_clipboard()
    if not content or #content == 0 then
        vim.notify("Clipboard empty or tool failed", vim.log.levels.WARN)
        return
    end
    content = content:gsub("\n$", "")
    local row = vim.fn.line(".")
    vim.api.nvim_put(vim.split(content, "\n"), "c", true, true)
    local endrow = vim.fn.line(".") - 1
    vim.cmd(("%d,%dnormal! ="):format(row, endrow))
    if vim.lsp.buf.format then
        pcall(vim.lsp.buf.format, {
            async = false,
            range = {
                start = { row - 1, 0 },
                ["end"] = { endrow, 0 },
            },
        })
    end
end

function C.setup_keymaps()
    local opts = { silent = true, noremap = true }

    vim.keymap.set("v", "<leader>Cs", ":Copy<CR>", vim.tbl_extend("force", opts, { desc = "Copy to system clipboard" }))
    vim.keymap.set(
        "n",
        "<leader>Cp",
        ":Paste<CR>",
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
end

function C.setup(opts)
    opts = opts or {}
    local silent = opts.silent or false
    local log_level = opts.log_level or vim.log.levels.INFO

    local function log(msg, level)
        level = level or vim.log.levels.INFO
        if level >= log_level and not silent then
            vim.notify(msg, level)
        end
    end

    if has_clipboard() then
        vim.o.clipboard = "unnamedplus"
        log("Clipboard integration enabled", vim.log.levels.DEBUG)
    else
        log("No clipboard provider found; using manual commands", vim.log.levels.WARN)
    end

    vim.api.nvim_create_user_command("Copy", function(a)
        if a.range > 0 then
            local content = table.concat(vim.api.nvim_buf_get_lines(0, a.line1 - 1, a.line2, false), "\n")
            system_copy(content)
            log("Copied selection to system clipboard", vim.log.levels.INFO)
        else
            log("Select text first", vim.log.levels.ERROR)
        end
    end, { range = true, desc = "Copy to system clipboard" })

    vim.api.nvim_create_user_command("Paste", paste, { desc = "Paste from system clipboard" })

    C.setup_keymaps()
    log("Clipboard keymaps configured", vim.log.levels.DEBUG)
end

return C
