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
    ../../modules/nix-tools.nix
    ../../modules/plover.nix
    ../../modules/r.nix
    ../../modules/shells.nix
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
    opencode
    amp-cli
    onefetch
    prettier
    zoom-us
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

}
