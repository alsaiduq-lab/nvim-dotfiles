-- TODO: fix it up

return {
    {
        "Zeioth/compiler.nvim",
        dependencies = {
            "stevearc/overseer.nvim",
            "nvim-telescope/telescope.nvim",
            "rcarriga/nvim-notify",
            "nvim-tree/nvim-web-devicons",
        },
        build = function()
            local deps = { "overseer.nvim", "telescope.nvim", "nvim-notify" }
            for _, dep in ipairs(deps) do
                if not pcall(require, dep:gsub("%.nvim", "")) then
                    vim.notify("❌ Missing dependency: " .. dep, vim.log.levels.ERROR)
                end
            end
        end,
        lazy = false,
        ft = { "cpp", "c", "rust", "java", "go", "haskell", "ocaml" },
        init = function()
            vim.g.compiler_output_win_max_height = 20
            vim.g.compiler_wrap_output = true
            vim.g.compiler_success_highlight = "DiffAdd"
            vim.g.compiler_error_highlight = "DiffDelete"
        end,
        config = function()
            local cache = {
                file_paths = {},
                compiler_checks = {},
                compilation_timeout = 30,
            }

            local function cleanup_temp_files(pattern)
                local files = vim.fn.glob(pattern, true, true)
                for _, file in ipairs(files) do
                    pcall(vim.fn.delete, file)
                end
            end

            local function get_debug_context()
                return {
                    pwd = vim.fn.getcwd(),
                    file = vim.fn.expand("%:p"),
                    filetype = vim.bo.filetype,
                    cargo_root = vim.fn.findfile("Cargo.toml", vim.fn.expand("%:p:h") .. ";"),
                    cabal_root = vim.fn.findfile("*.cabal", vim.fn.expand("%:p:h") .. ";"),
                }
            end

            local function notify(msg, level, enable_debug)
                level = level or vim.log.levels.INFO
                local info = debug.getinfo(2, "Sl")
                local location = string.format("%s:%d", info.source, info.currentline)

                if enable_debug then
                    msg = string.format(
                        "🐛 [DEBUG][%s] %s\nContext: %s",
                        location,
                        msg,
                        vim.inspect(get_debug_context())
                    )
                else
                    msg = string.format("ℹ️ [%s] %s", location, msg)
                end

                vim.schedule(function()
                    vim.notify(msg, level)
                end)
            end

            local function notify_error(msg)
                notify("❌ " .. msg, vim.log.levels.ERROR, true)
            end

            local function safe_mkdir(dir, mode)
                mode = mode or 448
                if vim.fn.isdirectory(dir) == 0 then
                    return vim.fn.mkdir(dir, "p", mode) == 1
                end
                return true
            end

            local function manage_logs(dir, keep_count)
                local old_logs = vim.fn.glob(dir .. "/*.log", true, true)
                if #old_logs > keep_count then
                    table.sort(old_logs)
                    for i = 1, #old_logs - keep_count do
                        pcall(vim.fn.delete, old_logs[i])
                    end
                end
            end

            local function validate_file_path()
                local current_file = vim.fn.expand("%:p")
                local cache_key = current_file .. tostring(vim.fn.getftime(current_file))

                if cache.file_paths[cache_key] then
                    return cache.file_paths[cache_key]
                end

                local current_dir = vim.fn.expand("%:p:h")

                if vim.fn.filereadable(current_file) == 0 then
                    notify_error(string.format("File not found: %s", current_file))
                    return false
                end

                if vim.fn.isdirectory(current_dir) == 0 then
                    notify_error(string.format("Directory not found: %s", current_dir))
                    return false
                end

                local result = current_dir
                if vim.bo.filetype == "rust" then
                    local cargo_toml = vim.fn.findfile("Cargo.toml", current_dir .. ";")
                    if cargo_toml ~= "" then
                        result = vim.fn.fnamemodify(cargo_toml, ":p:h")
                    end
                elseif vim.bo.filetype == "haskell" then
                    local cabal_file = vim.fn.findfile("*.cabal", current_dir .. ";")
                    if cabal_file ~= "" then
                        result = vim.fn.fnamemodify(cabal_file, ":p:h")
                    end
                end

                cache.file_paths[cache_key] = result
                return result
            end

            local compiler_commands = {
                cpp = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "g++ -Wall -Wextra -O2 %s -o %s && rm -rf bin/",
                            vim.fn.shellescape(current_file),
                            vim.fn.shellescape(output_file)
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
                c = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "gcc -Wall -Wextra -O2 %s -o %s && rm -rf bin/",
                            vim.fn.shellescape(current_file),
                            vim.fn.shellescape(output_file)
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
                rust = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "rustc %s -o %s && rm -rf bin/",
                            vim.fn.shellescape(current_file),
                            vim.fn.shellescape(output_file)
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
                java = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "javac %s -d %s && rm -rf bin/",
                            vim.fn.shellescape(current_file),
                            vim.fn.shellescape(vim.fn.fnamemodify(output_file, ":h"))
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
                go = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "go build -o %s %s && rm -rf bin/",
                            vim.fn.shellescape(output_file),
                            vim.fn.shellescape(current_file)
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
                haskell = function(current_file, output_file)
                    local function find_project_root()
                        local current_dir = vim.fn.expand("%:p:h")
                        local project_files = {
                            stack = vim.fn.findfile("stack.yaml", current_dir .. ";"),
                            cabal = vim.fn.findfile("*.cabal", current_dir .. ";"),
                            hpack = vim.fn.findfile("package.yaml", current_dir .. ";"),
                        }

                        if project_files.stack ~= "" then
                            return { type = "stack", root = vim.fn.fnamemodify(project_files.stack, ":p:h") }
                        elseif project_files.cabal ~= "" then
                            return { type = "cabal", root = vim.fn.fnamemodify(project_files.cabal, ":p:h") }
                        else
                            return { type = "ghc", root = vim.fn.fnamemodify(current_file, ":p:h") }
                        end
                    end

                    local project = find_project_root()
                    local output_dir = vim.fn.fnamemodify(output_file, ":h")

                    if project.type == "stack" then
                        return {
                            cmd = string.format(
                                "cd %s && stack build && stack exec $(basename %s .hs)",
                                vim.fn.shellescape(project.root),
                                vim.fn.shellescape(current_file)
                            ),
                            timeout = cache.compilation_timeout * 2,
                        }
                    elseif project.type == "cabal" then
                        return {
                            cmd = string.format("cd %s && cabal build && cabal run", vim.fn.shellescape(project.root)),
                            timeout = cache.compilation_timeout * 2,
                        }
                    else
                        return {
                            cmd = string.format(
                                "cd %s && ghc -Wall -O2 -outputdir %s -i. %s -o %s && rm -rf *.hi *.o",
                                vim.fn.shellescape(project.root),
                                vim.fn.shellescape(output_dir),
                                vim.fn.shellescape(vim.fn.fnamemodify(current_file, ":t")),
                                vim.fn.shellescape(output_file)
                            ),
                            timeout = cache.compilation_timeout,
                        }
                    end
                end,
                ocaml = function(current_file, output_file)
                    return {
                        cmd = string.format(
                            "ocamlc -o %s %s && rm -rf bin/",
                            vim.fn.shellescape(output_file),
                            vim.fn.shellescape(current_file)
                        ),
                        timeout = cache.compilation_timeout,
                    }
                end,
            }

            local ok, compiler = pcall(require, "compiler")
            if not ok then
                notify_error("Failed to load compiler.nvim")
                return
            end

            compiler.setup({
                task_list = {
                    direction = "bottom",
                    min_height = 25,
                    max_height = 25,
                    default_detail = 1,
                    auto_close = false,
                    auto_jump = true,
                },
                output_win = {
                    auto_close_on_success = false,
                    scroll_output = true,
                },
                diagnostics = {
                    enable = true,
                    virtual_text = true,
                },
                on_error = function(err)
                    notify_error("Compiler error: " .. tostring(err))
                    cleanup_temp_files("/tmp/nvim_compile_*")
                    vim.fn.system("rm -rf bin/")
                end,
            })

            vim.api.nvim_create_user_command("CompileAndRun", function()
                local required_compilers = {
                    cpp = "g++",
                    c = "gcc",
                    rust = "rustc",
                    haskell = "ghc",
                    ocaml = "ocamlc",
                    go = "go",
                    java = "javac",
                }

                local current_ft = vim.bo.filetype
                if not current_ft or current_ft == "" then
                    notify_error("No filetype detected")
                    return
                end

                local required_compiler = required_compilers[current_ft]
                if not required_compiler then
                    notify_error("Unsupported filetype: " .. current_ft)
                    return
                end

                if not cache.compiler_checks[required_compiler] then
                    if not vim.fn.executable(required_compiler) then
                        notify_error(string.format("Required compiler '%s' not found", required_compiler))
                        return
                    end
                    cache.compiler_checks[required_compiler] = true
                end

                local current_file = vim.fn.expand("%:p")
                if not current_file or current_file == "" then
                    notify_error("No file open")
                    return
                end

                local working_dir = validate_file_path()
                if not working_dir then
                    return
                end

                local output_dir = vim.fn.expand("~/.cache/nvim/compiler/")
                if not safe_mkdir(output_dir, 448) then
                    notify_error("Failed to create output directory")
                    return
                end

                local compilation_cmd = compiler_commands[current_ft]
                if compilation_cmd then
                    local output_file =
                        string.format("/tmp/nvim_compile_%s_%s", vim.fn.getpid(), os.date("%Y%m%d_%H%M%S"))

                    local cmd_info = compilation_cmd(current_file, output_file)
                    notify("Executing command: " .. cmd_info.cmd, vim.log.levels.INFO, true)

                    vim.schedule(function()
                        vim.cmd("OverseerRunCmd " .. cmd_info.cmd)
                    end)
                else
                    notify_error("Failed to generate compilation command")
                end
            end, {})

            local function safe_keymap(mode, lhs, rhs, opts)
                opts = opts or {}
                opts.silent = opts.silent ~= false
                opts.noremap = opts.noremap ~= false

                if not pcall(vim.api.nvim_set_keymap, mode, lhs, rhs, opts) then
                    notify_error(string.format("Failed to set keymap: %s -> %s", lhs, rhs))
                end
            end

            safe_keymap("n", "<F6>", "<cmd>CompilerOpen<cr>", { desc = "Open Compiler" })
            safe_keymap(
                "n",
                "<S-F6>",
                "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>",
                { desc = "Stop & Retry Compilation" }
            )
            safe_keymap("n", "<F7>", "<cmd>CompileAndRun<cr>", { desc = "Compile & Run" })

            vim.api.nvim_create_autocmd("VimLeavePre", {
                callback = function()
                    cleanup_temp_files("/tmp/nvim_compile_*")
                    vim.fn.delete(vim.fn.expand("~/.cache/nvim/compiler/"), "rf")
                    vim.fn.system("rm -rf bin/")
                end,
            })
        end,
    },
}
