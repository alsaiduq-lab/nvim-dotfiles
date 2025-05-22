{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
    in {
      devShells.default = pkgs.mkShell {
        name = "Cobray";

        buildInputs = [
          pkgs.neovim
          pkgs.git
          pkgs.curl
          pkgs.wget
          pkgs.unzip
          pkgs.gnumake
          pkgs.cmake
          pkgs.gcc
          pkgs.nodejs
          pythonEnv
          pkgs.ripgrep
          pkgs.fd
          pkgs.fzf
          pkgs.bat
          pkgs.lua-language-server
          pkgs.rust-analyzer
          pkgs.gopls
          pkgs.clang-tools
          pkgs.nil
          pkgs.eza
          pkgs.htop
          pkgs.jq
        ];

        shellHook = ''
          export EDITOR="nvim"
          export VISUAL="nvim"
        '';
      };
    });
}
