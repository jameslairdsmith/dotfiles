{ pkgs, ... }:
let
  dotsDir = ../..;
  vscodeConfigDir = "Library/Application Support/Code/User";

  # Keep portable, hand-editable settings in JSON. Nix-derived values are
  # merged afterwards so they take precedence if a key appears in both sets.
  generalSettings = builtins.fromJSON (builtins.readFile "${dotsDir}/vscode/settings.json");
  nixSettings = {
    "nix.formatterPath" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings".nixd.formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
  };
in
{
  home.file."${vscodeConfigDir}/keybindings.json".source = "${dotsDir}/vscode/keybindings.json";

  programs.vscode = {
    enable = true;

    argvSettings = {
      enable-crash-reporter = false;
    };

    profiles.default = {
      userSettings = generalSettings // nixSettings;

      # Data science extensions are absent because I instead use Positron

      extensions = with pkgs.vscode-marketplace; [
        # Nix
        jnoortheen.nix-ide

        # YAML
        redhat.vscode-yaml

        # General formatting
        esbenp.prettier-vscode

        # PDF
        tomoki1207.pdf

        # Elm
        elmtooling.elm-ls-vscode
        elm-land.elm-land
        # dependency of elm extension
        hbenl.vscode-test-explorer
        # Required by hbenl.vscode-test-explorer
        ms-vscode.test-adapter-converter

        # General text editing
        vscodevim.vim
        #vspacecode.vspacecode
        #vspacecode.whichkey

        # Typst
        myriad-dreamin.tinymist
      ];
    };
  };
}
