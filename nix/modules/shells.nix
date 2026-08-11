{ ... }:
let
  shellAliases = {
    hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
  };
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ../../fish/config.fish;
    inherit shellAliases;
  };

  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ../../zsh/zshrc;
    inherit shellAliases;
  };

  programs.bash = {
    enable = true;
    profileExtra = builtins.readFile ../../bash/bash-profile;
    inherit shellAliases;
  };
}
