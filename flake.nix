{
  description = "My dotfiles management flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "aarch64-darwin"; # Use "x86_64-darwin" for Intel Macs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true; # This is the magic line
    };

    myVscode = pkgs.vscode-with-extensions.override {
      vscodeExtensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide # Nix language support + formatting
      ];
    };
  in {
    devShells."aarch64-darwin".default = pkgs.mkShell {
      packages = [
        pkgs.nixfmt
        pkgs.alejandra
        pkgs.nixd
        myVscode
      ];
      shellHook = ''
        echo "welcome to the shell!"
      '';
      NIXPKGS_ALLOW_UNFREE = 1;
    };
  };
}
