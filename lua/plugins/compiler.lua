-- Mostly for nix; falls back to host tools if nix missing
return {
    {
        "Zeioth/compiler.nvim",
        dependencies = {
            "stevearc/overseer.nvim",
            "nvim-telescope/telescope.nvim",
            "rcarriga/nvim-notify",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,
        ft = {
            "c",
            "cpp",
            "rust",
            "go",
            "java",
            "haskell",
            "ocaml",
            "zig",
            "nim",
            "swift",
            "kotlin",
            "python",
            "javascript",
            "typescript",
            "bash",
            "sh",
            "fish",
            "lua",
            "ruby",
            "perl",
            "php",
            "r",
            "julia",
        },
        init = function()
            vim.g.compiler_output_win_max_height = 20
            vim.g.compiler_wrap_output = true
            vim.g.compiler_success_highlight = "DiffAdd"
            vim.g.compiler_error_highlight = "DiffDelete"
        end,
        config = function()
            local ok, compiler = pcall(require, "compiler")
            if not ok then
                vim.notify("compiler.nvim not found!", vim.log.levels.ERROR)
                return
            end

            local timeout_s = 30
            local function note(msg, lvl)
                vim.schedule(function()
                    vim.notify(msg, lvl or vim.log.levels.INFO)
                end)
            end
            local function have(cmd)
                return vim.fn.executable(cmd) == 1
            end
            local function shellescape(s)
                return vim.fn.shellescape(s)
            end

            local function project_flake_dir(start)
                local f = vim.fn.findfile("flake.nix", start .. ";")
                return f ~= "" and vim.fn.fnamemodify(f, ":p:h") or nil
            end

            local function shebang(file)
                local l = (vim.fn.readfile(file, "", 1)[1] or "")
                if l:sub(1, 2) == "#!" then
                    local rest = l:gsub("^#!%s*", "")
                    local env = rest:match("env%s+([%w%-%._]+)")
                    if env then
                        return env
                    end
                    local bin = rest:match("([^/%s]+)$")
                    return bin
                end
                return nil
            end

            local toolchains = {
                c = {
                    pkgs = { "coreutils", "gcc" },
                    run = function(f)
                        return ('gcc -Wall -Wextra -O2 %s -o "$tmp/a.out" && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                cpp = {
                    pkgs = { "coreutils", "gcc" },
                    run = function(f)
                        return ('g++ -Wall -Wextra -O2 %s -o "$tmp/a.out" && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                rust = {
                    pkgs = { "coreutils", "rustc" },
                    run = function(f)
                        return ('rustc -O %s -o "$tmp/a.out" && timeout "$TIMEOUT" "$tmp/a.out"'):format(shellescape(f))
                    end,
                },
                go = {
                    pkgs = { "coreutils", "go" },
                    run = function(f)
                        return ('GOFLAGS="-mod=mod" go build -o "$tmp/a.out" %s && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                java = {
                    pkgs = { "coreutils", "jdk" },
                    run = function(f)
                        return ('javac %s -d "$tmp" && timeout "$TIMEOUT" java -cp "$tmp" %s'):format(
                            shellescape(f),
                            vim.fn.fnamemodify(f, ":t:r")
                        )
                    end,
                },
                haskell = {
                    pkgs = { "coreutils", "ghc" },
                    run = function(f)
                        return ('ghc -O2 -outputdir "$tmp" -o "$tmp/a.out" %s >/dev/null && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                ocaml = {
                    pkgs = { "coreutils", "ocaml" },
                    run = function(f)
                        return ('ocamlc -o "$tmp/a.out" %s && timeout "$TIMEOUT" "$tmp/a.out"'):format(shellescape(f))
                    end,
                },
                zig = {
                    pkgs = { "coreutils", "zig" },
                    run = function(f)
                        return ('zig build-exe -O ReleaseFast -femit-bin="$tmp/a.out" %s && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                nim = {
                    pkgs = { "coreutils", "nim" },
                    run = function(f)
                        return ('nim c -d:release --out:"$tmp/a.out" %s && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                swift = {
                    pkgs = { "coreutils", "swift" },
                    run = function(f)
                        return ('swiftc -O -o "$tmp/a.out" %s && timeout "$TIMEOUT" "$tmp/a.out"'):format(
                            shellescape(f)
                        )
                    end,
                },
                kotlin = {
                    pkgs = { "coreutils", "kotlin", "jdk" },
                    run = function(f)
                        return ('kotlinc %s -include-runtime -d "$tmp/app.jar" && timeout "$TIMEOUT" java -jar "$tmp/app.jar"'):format(
                            shellescape(f)
                        )
                    end,
                },

                python = {
                    pkgs = { "coreutils", "python3" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" python3 %s'):format(shellescape(f))
                    end,
                },
                javascript = {
                    pkgs = { "coreutils", "nodejs" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" node %s'):format(shellescape(f))
                    end,
                },
                typescript = {
                    pkgs = { "coreutils", "nodejs", "nodePackages.ts-node" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" ts-node %s'):format(shellescape(f))
                    end,
                },
                bash = {
                    pkgs = { "coreutils", "bash" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" bash %s'):format(shellescape(f))
                    end,
                },
                sh = {
                    pkgs = { "coreutils", "bash" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" bash %s'):format(shellescape(f))
                    end,
                },
                fish = {
                    pkgs = { "coreutils", "fish" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" fish %s'):format(shellescape(f))
                    end,
                },
                lua = {
                    pkgs = { "coreutils", "lua" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" lua %s'):format(shellescape(f))
                    end,
                },
                ruby = {
                    pkgs = { "coreutils", "ruby" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" ruby %s'):format(shellescape(f))
                    end,
                },
                perl = {
                    pkgs = { "coreutils", "perl" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" perl %s'):format(shellescape(f))
                    end,
                },
                php = {
                    pkgs = { "coreutils", "php" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" php %s'):format(shellescape(f))
                    end,
                },
                r = {
                    pkgs = { "coreutils", "R" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" Rscript %s'):format(shellescape(f))
                    end,
                },
                julia = {
                    pkgs = { "coreutils", "julia" },
                    run = function(f)
                        return ('timeout "$TIMEOUT" julia %s'):format(shellescape(f))
                    end,
                },
            }

            local interp_map = {
                python = { pkgs = { "coreutils", "python3" }, bin = "python3" },
                python3 = { pkgs = { "coreutils", "python3" }, bin = "python3" },
                node = { pkgs = { "coreutils", "nodejs" }, bin = "node" },
                deno = { pkgs = { "coreutils", "deno" }, bin = "deno run" },
                bash = { pkgs = { "coreutils", "bash" }, bin = "bash" },
                sh = { pkgs = { "coreutils", "bash" }, bin = "bash" },
                fish = { pkgs = { "coreutils", "fish" }, bin = "fish" },
                lua = { pkgs = { "coreutils", "lua" }, bin = "lua" },
                ruby = { pkgs = { "coreutils", "ruby" }, bin = "ruby" },
                perl = { pkgs = { "coreutils", "perl" }, bin = "perl" },
                php = { pkgs = { "coreutils", "php" }, bin = "php" },
                Rscript = { pkgs = { "coreutils", "R" }, bin = "Rscript" },
                julia = { pkgs = { "coreutils", "julia" }, bin = "julia" },
            }

            local function resolve(file, ft)
                if toolchains[ft] then
                    return toolchains[ft].pkgs, toolchains[ft].run(file)
                end
                local sb = shebang(file)
                if sb and interp_map[sb] then
                    local m = interp_map[sb]
                    return m.pkgs, ('timeout "$TIMEOUT" %s %s'):format(m.bin, shellescape(file))
                end
                local ext = vim.fn.fnamemodify(file, ":e")
                local ext_map = {
                    c = "c",
                    cc = "cpp",
                    cpp = "cpp",
                    hpp = "cpp",
                    hs = "haskell",
                    ml = "ocaml",
                    rs = "rust",
                    go = "go",
                    js = "javascript",
                    ts = "typescript",
                    py = "python",
                    sh = "bash",
                    fish = "fish",
                    lua = "lua",
                    rb = "ruby",
                    pl = "perl",
                    php = "php",
                    r = "r",
                    jl = "julia",
                    kt = "kotlin",
                    swift = "swift",
                    zig = "zig",
                    nim = "nim",
                }
                local ftk = ext_map[ext]
                if ftk and toolchains[ftk] then
                    return toolchains[ftk].pkgs, toolchains[ftk].run(file)
                end
                return nil, nil
            end

            local function nix_wrap(workdir, pkgs, inner)
                local T = tostring(math.max(1, timeout_s))
                local sh = table.concat({
                    "set -eu",
                    'tmp="$(mktemp -d)"',
                    "trap 'rm -rf \"$tmp\"' EXIT",
                    "ulimit -t " .. T .. " || true",
                    "ulimit -v 2097152 || true",
                    "ulimit -f 524288 || true",
                    "export TIMEOUT=" .. T,
                    inner,
                }, " && ")
                if have("nix") then
                    local NIX = 'nix --extra-experimental-features "nix-command flakes"'
                    local flake_dir = project_flake_dir(workdir)
                    if flake_dir then
                        return ("cd %s && %s develop .# --command sh -lc %s"):format(
                            shellescape(flake_dir),
                            NIX,
                            shellescape("cd " .. shellescape(workdir) .. " && " .. sh)
                        )
                    else
                        local args = {}
                        for _, p in ipairs(pkgs or { "coreutils" }) do
                            table.insert(args, "nixpkgs#" .. p)
                        end
                        return ("%s shell %s --command sh -lc %s"):format(
                            NIX,
                            table.concat(args, " "),
                            shellescape("cd " .. shellescape(workdir) .. " && " .. sh)
                        )
                    end
                else
                    return ("sh -lc %s"):format(shellescape("cd " .. shellescape(workdir) .. " && " .. sh))
                end
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
                output_win = { auto_close_on_success = false, scroll_output = true },
                diagnostics = { enable = true, virtual_text = true },
                on_error = function(err)
                    note("❌ " .. tostring(err), vim.log.levels.ERROR)
                end,
            })

            vim.api.nvim_create_user_command("CompileAndRun", function()
                local file = vim.fn.expand("%:p")
                if file == "" or vim.fn.filereadable(file) == 0 then
                    return note("No readable file!", vim.log.levels.ERROR)
                end
                local ft = vim.bo.filetype
                local pkgs, inner = resolve(file, ft)
                if not inner then
                    return note("Unsupported filetype and no usable shebang", vim.log.levels.ERROR)
                end
                local cmd = nix_wrap(vim.fn.fnamemodify(file, ":h"), pkgs, inner)
                vim.cmd("OverseerRunCmd " .. cmd)
            end, {})

            local function map(mode, lhs, rhs, desc)
                pcall(vim.keymap.set, mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
            end
            map("n", "<F6>", "<cmd>CompilerOpen<cr>", "Open Compiler")
            map("n", "<S-F6>", "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", "Stop & Retry Compilation")
            map("n", "<F7>", "<cmd>CompileAndRun<cr>", "Compile & Run")
            map("n", "<C-F6>", "<cmd>CompilerStop<cr>", "Stop Compilation")
        end,
    },
}
