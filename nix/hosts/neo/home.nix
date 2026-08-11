{
  pkgs,
  ...
}:
let
  dotsDir = ../../..;
in
{
  imports = [
    ../../modules/emacs.nix
    ../../modules/git.nix
    ../../modules/ghostty.nix
    ../../modules/plover.nix
    ../../modules/r.nix
    ../../modules/positron.nix
    ../../modules/zed.nix
    ../../modules/vscode.nix
    ../../modules/worktrunk.nix
    ../../modules/treefmt.nix
    ../../modules/pi.nix
  ];

  home.username = "jls";
  home.homeDirectory = "/Users/jls";
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # Extra packages not covered in modules
  home.packages = with pkgs; [
    hello
    tmux
    nixfmt
    opencode
    alejandra
    nixd
    amp-cli
    onefetch
    zoom-us

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.file = {
    ".config/amp/AGENTS.md".source = "${dotsDir}/agents/AGENTS.md";
  };

  home.sessionVariables = {
    EDITOR = "vim";
    #SHELL = "bash";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile "${dotsDir}/fish/config.fish";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.zsh = {
    enable = true;
    initContent = builtins.readFile "${dotsDir}/zsh/zshrc";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.bash = {
    enable = true;
    profileExtra = builtins.readFile "${dotsDir}/bash/bash-profile";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

}
