local W = {}

local function find_python3_host_prog()
    local possible_paths = {
        vim.fn.expand("$LOCALAPPDATA") .. "/Programs/Python/Python312/python.exe",
        vim.fn.expand("$LOCALAPPDATA") .. "/Programs/Python/Python311/python.exe",
        vim.fn.expand("$LOCALAPPDATA") .. "/Programs/Python/Python310/python.exe",
        vim.fn.expand("$LOCALAPPDATA") .. "/Programs/Python/Python39/python.exe",
        vim.fn.expand("$LOCALAPPDATA") .. "/Microsoft/WindowsApps/python.exe",
        "C:/Python312/python.exe",
        "C:/Python311/python.exe",
        "C:/Python310/python.exe",
        "C:/Python39/python.exe",
    }

    for _, path in ipairs(possible_paths) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return nil
end

function W.setup()
    vim.g.loaded_python_provider = 0

    local py3_prog = find_python3_host_prog()
    if py3_prog then
        vim.g.python3_host_prog = py3_prog
    else
        vim.notify("No suitable python3 executable found for Neovim.", vim.log.levels.WARN)
    end
    vim.opt.emoji = true
    vim.opt.encoding = "utf-8"
    vim.opt.fileencoding = "utf-8"
    vim.opt.ambiwidth = "single"
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*",
        callback = function()
            vim.opt_local.fileencoding = "utf-8"
            vim.opt_local.bomb = false
        end,
    })
end

return W
