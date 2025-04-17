local M = {}

local function find_python()
    local candidates = {
        vim.env.PYTHON_PATH,
        vim.env.HOME .. "/.virtualenvs/neovim/bin/python3",
        vim.env.HOME .. "/.venv/bin/python3",
        "/run/current-system/sw/bin/python3",
        "/etc/profiles/per-user/" .. vim.env.USER .. "/bin/python3",
        "/usr/bin/python3",
    }

    for _, python in ipairs(candidates) do
        if python and vim.fn.executable(python) == 1 then
            return python
        end
    end

    local python_from_path = vim.fn.exepath("python3")
    if python_from_path ~= "" then
        return python_from_path
    end

    return nil
end

function M.setup()
    local python3 = find_python()
    if python3 then
        vim.g.python3_host_prog = python3
    else
        vim.notify("Warning: No usable python3 interpreter found for Neovim's Python provider.", vim.log.levels.WARN)
    end
end

return M
