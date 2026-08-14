{ ... }:
let
  shellAliases = {
    dr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    hr = "sh -c 'generation=$(nix build --no-link --print-out-paths \"$HOME/projects/dotfiles/nix/hosts/neo#darwinConfigurations.neo.config.home-manager.users.jls.home.activationPackage\") && \"$generation/activate\"'";
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
