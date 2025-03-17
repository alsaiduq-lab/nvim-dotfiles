let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/a1185f4064c18a5db37c5c84e5638c78b46e3341.tar.gz";
    sha256 = "0ipjb56fdhfvhgnrw0rvp89g0mplpyhjil29fqdcpmv4ablbadqc";
  };
  pkgs = import nixpkgs {};
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
    requests
    debugpy
  ]);
  repoOwner = "alsaiduq-lab";
  repoName = "private-stuff";
  imagePath = "strike_freedom.png";
  rawImageUrl = "https://raw.githubusercontent.com/${repoOwner}/${repoName}/master/${imagePath}";
  kittyImageScript = pkgs.writeTextFile {
    name = "kitty-image.py";
    text = ''
      import os
      import requests
      import base64
      import sys
      token = os.environ.get("GITHUB_TOKEN")
      if not token:
          print("Error: GITHUB_TOKEN environment variable not set", file=sys.stderr)
          sys.exit(1)
      headers = {"Authorization": f"token {token}"}
      image_url = "${rawImageUrl}"
      response = requests.get(image_url, headers=headers)
      if response.status_code == 200:
          image_data = base64.b64encode(response.content).decode('ascii')
          print(f"\033_Gf=100,a=T;{image_data}\033\\")
      else:
          print(f"Failed to fetch image (status: {response.status_code})", file=sys.stderr)
          sys.exit(1)
    '';
  };
in
pkgs.mkShell {
  name = "cobrays-nvim-cloud-shell";
  buildInputs = with pkgs; [
    neovim
    lua
    luajit
    luaPackages.luarocks
    git
    ripgrep
    gcc
    nil
    lua-language-server
    curl
    unzip
    nodejs
    pythonWithPackages
  ];
  shellHook = ''
    clear
    export NVIM_CONFIG_DIR="$(pwd)"
    export LUA_PATH="${pkgs.luajit}/share/lua/5.1/?.lua;;"
    export LUA_CPATH="${pkgs.luajit}/lib/lua/5.1/?.so;;"
    export PATH=$PATH:$HOME/.local/share/nvim/mason/bin
    ${pythonWithPackages}/bin/python ${kittyImageScript}
    echo "Config directory: $NVIM_CONFIG_DIR"
  '';
}
