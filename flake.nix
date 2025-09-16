{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      mkDevShellFor = python: let
        pythonEnv = python.withPackages (ps:
          with ps; [
            ruff
            requests
            pynvim
          ]);
      in
        pkgs.mkShell {
          packages = with pkgs; [
            neovim
            git
            curl
            wget
            unzip
            gnumake
            cmake
            gcc
            ripgrep
            fd
            fzf
            bat
            eza
            htop
            jq
            lua-language-server
            rust-analyzer
            gopls
            clang-tools
            nil
            nodejs
            pythonEnv
            nodePackages.typescript
            nodePackages.typescript-language-server
            nodePackages.eslint
            nodePackages.prettier
            nodePackages.vscode-langservers-extracted
            nodePackages.bash-language-server
            nodePackages.yaml-language-server
          ];

          shellHook = ''
            export EDITOR="nvim"
            export VISUAL="nvim"
          '';
        };
    in {
      devShells.default = mkDevShellFor pkgs.python311;
      devShells.py311 = mkDevShellFor pkgs.python311;
      devShells.py312 = mkDevShellFor pkgs.python312;
    });
}
