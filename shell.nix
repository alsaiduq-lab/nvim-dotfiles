{pkgs ? import <nixpkgs> {}}: let
  pythonEnv = pkgs.python311.withPackages (ps:
    with ps; [
      debugpy
      ruff
      requests
      pynvim
    ]);

  nodePackages = with pkgs.nodePackages; [
    typescript
    typescript-language-server
    eslint
    prettier
    vscode-langservers-extracted
    bash-language-server
    yaml-language-server
  ];
  fetchStarshipConfig = pkgs.writeShellScriptBin "fetch-starship" ''
    if [ -z "$GITHUB_TOKEN" ]; then
      echo "Error: GITHUB_TOKEN environment variable is not set"
      exit 1
    fi
    if [ ! -f ~/.config/starship.toml ]; then
      mkdir -p ~/.config
      curl -s -H "Authorization: token $GITHUB_TOKEN" \
        https://raw.githubusercontent.com/alsaiduq-lab/i3-dotfiles/master/starship.toml \
        -o ~/.config/starship.toml
      if [ $? -eq 0 ]; then
        echo "✓ Successfully fetched starship.toml configuration"
      else
        echo "✗ Failed to fetch starship.toml configuration"
      fi
    fi
  '';
  setupMason = pkgs.writeShellScriptBin "setup-nvim-mason" ''
        MASON_DIR="$HOME/.local/share/nvim/mason"
        echo "Installing nvim requirements..."
        cat > /tmp/install_mason_tools.lua << 'EOF'
        local mason_registry = require("mason-registry")
        local packages = {
          "lua-language-server",
          "pyright",
          "rust-analyzer",
          "gopls",
          "clangd",
          "typescript-language-server",
          "css-lsp",
          "html-lsp",
          "json-lsp",
          "yaml-language-server",
          "marksman",
          "nil_ls",
          "stylua",
          "prettier",
          "gofmt",
          "shfmt",
          "yamlfmt",
          "ruff",
          "eslint_d",
          "shellcheck",
          "selene",
          "debugpy",
          "codelldb",
          "js-debug-adapter",
          "delve",
          "node-debug2-adapter",
          "bash-debug-adapter"
        }
        mason_registry:refresh()
        local function install_package(package_name)
          local success, result = pcall(function()
            local package = mason_registry.get_package(package_name)
            if not package:is_installed() then
              print("Installing " .. package_name)
              package:install()
              return true
            else
              print(package_name .. " is already installed")
              return false
            end
          end)
          if not success then
            print("Failed to install " .. package_name .. ": " .. tostring(result))
            return false
          end
          return result
        end
        local installed_count = 0
        local already_installed = 0
        local failed_packages = {}
        for _, package_name in ipairs(packages) do
          local installed = install_package(package_name)
          if installed == true then
            installed_count = installed_count + 1
          elseif installed == false then
            already_installed = already_installed + 1
          else
            table.insert(failed_packages, package_name)
          end
        end
        print("Mason setup complete!")
        print("  - " .. installed_count .. " packages newly installed")
        print("  - " .. already_installed .. " packages already installed")
        if #failed_packages > 0 then
          print("Failed to install the following packages:")
          for _, pkg in ipairs(failed_packages) do
            print("  - " .. pkg)
          end
          print("You may need to install them manually.")
        end
    EOF

        mkdir -p $MASON_DIR
        nvim --headless -c "luafile /tmp/install_mason_tools.lua" -c "qa!"
        for config_file in ~/.bashrc ~/.bash_profile ~/.zshrc; do
          if [ -f "$config_file" ]; then
            if ! grep -q "MASON_BIN_PATH" "$config_file"; then
              echo -e "\n# Add Mason binaries to PATH" >> "$config_file"
              echo "export MASON_BIN_PATH=\"$MASON_DIR/bin\"" >> "$config_file"
              echo "export PATH=\$PATH:\$MASON_BIN_PATH" >> "$config_file"
            fi
          fi
        done
        mkdir -p ~/.local/bin
        for bin in "$MASON_DIR"/bin/*; do
          if [ -x "$bin" ]; then
            target_link="$HOME/.local/bin/$(basename "$bin")"
            if [ ! -e "$target_link" ] || [ "$(readlink "$target_link")" != "$bin" ]; then
              ln -sf "$bin" "$target_link"
              echo "Linked $(basename "$bin") to ~/.local/bin/"
            fi
          fi
        done
        chmod -R u+x "$MASON_DIR/bin" 2>/dev/null
        echo "Mason tools have been installed"
        echo "Mason binaries are available in your PATH"
  '';

  setupFastfetch = pkgs.writeShellScriptBin "setup-fastfetch" ''
        mkdir -p ~/.config/fastfetch
        cat > ~/.config/fastfetch/config.jsonc << 'EOF'
    {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "display": {
            "separator": "   "
        },
        "modules": [
            "os",
            "kernel",
            "shell",
            "terminal",
            "cpu",
            "memory",
            "uptime",
            "packages",
            {
                "type": "custom",
                "format": "''${c5}NeoVim: ''${c7}''${subprocessOutput=nvim --version | head -n1 | awk '{print $2}'}''${clear}"
            },
            {
                "type": "custom",
                "format": "''${c6}Mason: ''${c7}''${subprocessOutput=ls -1 ~/.local/share/nvim/mason/bin 2>/dev/null | wc -l || echo '0'} packages''${clear}"
            }
        ],
        "logo": {
            "type": "file",
            "source": "~/.config/fastfetch/strike_freedom.png",
            "width": 30,
            "height": 10,
            "padding": {
                "top": 0,
                "left": 0
            }
        }
    }
    EOF
  '';
  fetchImage = pkgs.writeShellScriptBin "fetch-image" ''
    if [ -z "$GITHUB_TOKEN" ]; then
      echo "Error: GITHUB_TOKEN not set"
      exit 1
    fi
    mkdir -p ~/.config/fastfetch
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
      https://raw.githubusercontent.com/alsaiduq-lab/i3-dotfiles/master/strike_freedom.png \
      -o ~/.config/fastfetch/strike_freedom.png
  '';
in
  pkgs.mkShell {
    name = "cobrays-nvim-cloud-shell";
    buildInputs = with pkgs; [
      neovim-unwrapped
      git
      curl
      wget
      unzip
      gnumake
      cmake
      gcc
      nodejs
      nodePackages
      pythonEnv
      starship
      fastfetch
      zsh
      oh-my-zsh
      ripgrep
      fd
      fzf
      bat
      lua-language-server
      rust-analyzer
      gopls
      clang-tools
      nil
      eza
      htop
      jq
      fetchStarshipConfig
      setupMason
      setupFastfetch
      fetchImage
    ];

    # Inherit environment variables from parent shell
    shellHook = ''
      clear
      export NVIM_CONFIG_DIR="$(pwd)"
      export EDITOR="nvim"
      export VISUAL="nvim"
      
      if [ -d "$HOME/.local/bin" ]; then
        export PATH=$PATH:$HOME/.local/bin
      fi
      if [ -d "$HOME/.local/share/nvim/mason/bin" ]; then
        export PATH=$PATH:$HOME/.local/share/nvim/mason/bin
      fi
      export LUA_PATH="${pkgs.luajit}/share/lua/5.1/?.lua;${pkgs.luajit}/share/lua/5.1/?/init.lua;;"
      export LUA_CPATH="${pkgs.luajit}/lib/lua/5.1/?.so;;"
      export PYTHONPATH=${pythonEnv}/${pythonEnv.sitePackages}
      
      # Try both variable locations for GitHub token
      if [ -n "$GITHUB_TOKEN" ] || [ -n "$GITHUB_API_TOKEN" ]; then
        # Use whichever token is available
        [ -z "$GITHUB_TOKEN" ] && export GITHUB_TOKEN="$GITHUB_API_TOKEN"
        
        if [ ! -f ~/.config/starship.toml ]; then
          fetch-starship
        fi
        
        if [ ! -f ~/.config/fastfetch/strike_freedom.png ]; then
          fetch-image
        fi
      else
        echo "Warning: No GitHub token found in environment"
        echo "Set GITHUB_TOKEN env var to fetch resources from private repos"
      fi
      
      if [ ! -f ~/.config/fastfetch/config.jsonc ]; then
        setup-fastfetch
      fi
      
      if [ ! -d "$HOME/.local/share/nvim/mason/bin" ]; then
        setup-nvim-mason
      fi
      
      touch "$HOME/.nvim_cloud_setup_complete"
      eval "$(starship init bash)"
      
      if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
      
      echo "Config directory: $NVIM_CONFIG_DIR"
      if [ -f ./init.lua ]; then
        echo "Neovim config detected ✓"
      else
        echo "Note: No init.lua found in current directory"
      fi
    '';
  }
