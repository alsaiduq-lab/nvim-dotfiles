return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-global
      local vim = vim
      local ok_lsp, lspconfig = pcall(require, "lspconfig")
      local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
      if not (ok_lsp and ok_cmp) then return end

      local util, configs = require("lspconfig.util"), require("lspconfig.configs")
      local caps          = cmp.default_capabilities()
      local unpack_       = table.unpack or unpack

      local custom = {}
      do
        local path = vim.fn.stdpath("config") .. "/data/custom.lua"
        if vim.fn.filereadable(path) == 1 then
          local ok, mod = pcall(dofile, path)
          if ok and type(mod) == "table" then custom = mod end
        end
      end
      local skip = custom.skip or {}

      local function expand(v)
        if type(v) == "string" then
          return v
            :gsub("%$STATE", vim.fn.stdpath("state"))
            :gsub("%$CONFIG", vim.fn.stdpath("config"))
            :gsub("%$VIMRUNTIME", vim.env.VIMRUNTIME or vim.fn.expand("$VIMRUNTIME"))
        elseif type(v) == "table" then
          local out = {}
          for k, x in pairs(v) do out[k] = expand(x) end
          return out
        end
        return v
      end

      local function root_dir_from(cfg)
        if cfg.root_dir then return cfg.root_dir end
        if type(cfg.root_dir_patterns) == "table" then
          return util.root_pattern(unpack_(cfg.root_dir_patterns))
        end
        return util.root_pattern(".git")
      end

      local function resolve_auto_cmd(name, cmd)
        if name == "ty" and (cmd == "AUTO_TY" or cmd == nil) then
          if vim.fn.executable("ty") == 1  then return { "ty",  "server" } end
          if vim.fn.executable("uvx") == 1 then return { "uvx", "ty", "server" } end
          return { "ty", "server" }
        end
        return cmd
      end

      local declared = {}
      for name, cfg in pairs(custom.servers or {}) do
        declared[name] = true
        if not configs[name] then
          local cmd = cfg.cmd
          if type(cmd) == "function" then cmd = cmd() end
          cmd = resolve_auto_cmd(name, cmd)
          configs[name] = {
            default_config = {
              name = name,
              cmd = cmd or { name },
              filetypes = cfg.filetypes or {},
              root_dir = root_dir_from(cfg),
              settings = expand(cfg.settings or {}),
              init_options = expand(cfg.init_options or {}),
              single_file_support = (cfg.single_file_support ~= false),
            },
          }
        end
        local setup_cfg = vim.tbl_extend("force", { capabilities = caps }, cfg or {})
        if type(setup_cfg.cmd) == "function" then setup_cfg.cmd = setup_cfg.cmd() end
        setup_cfg.cmd         = resolve_auto_cmd(name, setup_cfg.cmd)
        if not setup_cfg.root_dir then setup_cfg.root_dir = root_dir_from(setup_cfg) end
        setup_cfg.settings     = expand(setup_cfg.settings or {})
        setup_cfg.init_options = expand(setup_cfg.init_options or {})
        lspconfig[name].setup(setup_cfg)
      end

      local ok_mason_lsp, mason_lsp = pcall(require, "mason-lspconfig")
      if ok_mason_lsp and mason_lsp.get_installed_servers then
        for _, server in ipairs(mason_lsp.get_installed_servers()) do
          if not skip[server] and not declared[server] and lspconfig[server] then
            lspconfig[server].setup({ capabilities = caps })
          end
        end
      end

      vim.keymap.set("n", "<leader>q", function()
        local diags  = vim.diagnostic.get(0)
        local groups = { ERROR = {}, WARN = {}, INFO = {}, HINT = {} }
        for _, d in ipairs(diags) do
          local sev = (d.severity == vim.diagnostic.severity.ERROR and "ERROR")
            or (d.severity == vim.diagnostic.severity.WARN and "WARN")
            or (d.severity == vim.diagnostic.severity.INFO and "INFO")
            or "HINT"
          groups[sev][#groups[sev]+1] =
            string.format("  [%d:%d] %s", d.lnum + 1, d.col + 1, (d.message or ""):gsub("\n", " "))
        end
        local out = {}
        for _, k in ipairs({ "ERROR", "WARN", "INFO", "HINT" }) do
          if #groups[k] > 0 then out[#out+1] = k .. ":"; vim.list_extend(out, groups[k]) end
        end
        if #out == 0 then out = { "No errors, warnings, info, or hints." } end

        local prev_win, prev_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(bufnr, "LSP Diagnostics")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
        vim.bo[bufnr].modifiable = false
        vim.bo[bufnr].buflisted = false
        vim.bo[bufnr].buftype = "nofile"
        vim.bo[bufnr].swapfile = false
        vim.bo[bufnr].bufhidden = "wipe"
        vim.cmd("botright split")
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, bufnr)
        vim.api.nvim_win_set_height(win, math.max(6, #out + 2))
        vim.api.nvim_create_autocmd("WinClosed", {
          once = true,
          callback = function()
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(prev_win) and vim.api.nvim_buf_is_valid(prev_buf) then
                vim.api.nvim_set_current_win(prev_win)
                vim.api.nvim_set_current_buf(prev_buf)
              end
            end)
          end,
        })
      end, { desc = "Show LSP diagnostics" })
    end,
  },
}

