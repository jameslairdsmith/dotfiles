{ ... }:
let
  shellAliases = {
    dr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    hr = "home-manager switch --flake ~/projects/dotfiles/nix/hosts/neo#jls";
    mf = "nvim -c 'let g:mini_files_standalone = v:true' -c 'lua require(\"mini.files\").open(nil, false)'";
    oil = "nvim -c 'Oil .'";
  };
in
{
  programs.fzf.enable = true;

  programs.zoxide.enable = true;

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
