local function system_git(cmd)
  local command = vim.fn.has('win32') == 1
    and ('cmd /c git ' .. cmd .. ' 2>nul')
    or ('git ' .. cmd .. ' 2>/dev/null')
  return vim.fn.system(command)
end

local function load_quotes()
  local config_path = vim.fn.stdpath("config")
  local quotes_path = config_path .. "/data/quotes.json"
  local quotes_file = io.open(quotes_path, "r")

  if not quotes_file then
    vim.notify("Could not load quotes.json", vim.log.levels.WARN)
    return {
      default = {
        "😳 quotes.json not found",
        "🤡 skill issue loading...",
        "✨ config needs help"
      }
    }
  end

  local content = quotes_file:read("*all")
  quotes_file:close()

  local success, decoded = pcall(vim.json.decode, content)
  if not success then
    vim.notify("Failed to parse quotes.json", vim.log.levels.ERROR)
    return {
      default = {
        "💀 quotes.json parse error",
        "🤡 json validation failed"
      }
    }
  end

  return decoded
end

local git_cache = {
  info = nil,
  last_update = 0
}

local function get_git_info(force_update)
  if not force_update and git_cache.info then
    return git_cache.info
  end

  local in_git_repo = system_git('rev-parse --is-inside-work-tree')
  if vim.v.shell_error ~= 0 then
    git_cache.info = nil
    return nil
  end

  local branch = system_git('branch --show-current'):gsub('\n', '')
  local remote_url = system_git('config --get remote.origin.url'):gsub('\n', '')

  if remote_url == '' then
    git_cache.info = {
      branch = branch,
      url = nil,
      is_private = true
    }
    return git_cache.info
  end

  local processed_url = remote_url
  if remote_url:match('^git@') then
    processed_url = remote_url:gsub('git@github.com:', 'https://github.com/')
  end
  processed_url = processed_url:gsub('%.git$', '')

  git_cache.info = {
    branch = branch,
    url = processed_url,
    is_private = false
  }

  return git_cache.info
end

local quotes_data = load_quotes()

local function get_quote(filetype)
  local file_quotes = quotes_data[filetype] or quotes_data.default
  if not file_quotes then
    return "⚠️ no quotes available"
  end
  return file_quotes[math.random(#file_quotes)]
end

local cached_git_info = get_git_info(true)

local session_quote = nil

return {
  "vyfor/cord.nvim",
  build = ":Cord update",
  opts = {
    enabled = true,
    log_level = vim.log.levels.OFF,
    debug = true,
    editor = {
      client = 'neovim',
      tooltip = 'The Superior Text Editor',
      icon = "neovim",
    },
    display = {
      show_time = true,
      show_repository = true,
      show_cursor_position = true,
      theme = "onyx",
      fallback_theme = "pastel",
      flavor = 'dark',
      swap_fields = false,
      swap_icons = false,
    },
    timestamp = {
      enabled = true,
      reset_on_idle = false,
      reset_on_change = false,
    },
    idle = {
      enabled = true,
      timeout = 300000,
      show_status = true,
      ignore_focus = true,
      unidle_on_focus = true,
      smart_idle = true,
      details = 'Idling',
      state = nil,
      tooltip = '💤',
      icon = nil,
    },
    text = {
      workspace = function(opts) return 'In ' .. opts.workspace end,
      editing = function(opts)
        local text = string.format('Editing %s - Line %s:%s', opts.filename, opts.cursor_line, opts.cursor_char)
        if vim.bo.modified then
          text = text .. ' [*]'
        end
        if cached_git_info and cached_git_info.branch then
          text = text .. string.format(' (%s)', cached_git_info.branch)
        end
        return text
      end,
      viewing = function(opts)
        return string.format('Viewing %s - Line %s:%s', opts.filename, opts.cursor_line, opts.cursor_char)
      end,
      file_browser = "Browsing project files",
      plugin_manager = "Managing plugins",
      lsp_manager = "Configuring language server",
      vcs = "Reviewing changes",
    },
    assets = {
      DiffviewFiles = {
        name = "Git Diff View",
        icon = "git",
        tooltip = get_quote("git"),
        type = "vcs",
      },
      MarkdownPreview = {
        name = "Markdown Preview",
        icon = "markdown",
        tooltip = get_quote("markdown"),
        type = "docs",
      },
    },
    hooks = {
      on_activity = function(_, activity)
        if not session_quote then
          local ft = vim.bo.filetype
          if ft == "" then
            ft = "default"
          end
          session_quote = get_quote(ft)
        end
        activity.state = session_quote
      end,
      on_workspace_change = function(_)
        cached_git_info = get_git_info(true)
      end
    },
    buttons = {
      {
        label = function(_)
          if cached_git_info and cached_git_info.url then
            return '📦 View Repository'
          end
          return '🌟 Portfolio'
        end,
        url = function(_)
          if cached_git_info and cached_git_info.url then
            return cached_git_info.url
          end
          return 'https://monaie.ca'
        end
      }
    },
    auto_connect = true,
    check_discord = true,
  },
  config = function()
    vim.api.nvim_create_user_command('Quote', function()
      local ft = vim.bo.filetype
      if ft == "" then
        ft = "default"
      end
      local quote = get_quote(ft)
      vim.print(string.format("Debug quote for filetype '%s': %s", ft, quote))
    end, {})

    pcall(function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            local ok, cord = pcall(require, "cord")
            if ok and cord and cord.state then
              pcall(function()
                return cord.state.is_connected
              end)
            end
          end)
        end,
      })
    end)
  end,
}
