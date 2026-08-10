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

      extensions = with pkgs.vscode-marketplace; [
        jnoortheen.nix-ide # Nix language support + formatting
        sourcegraph.amp
        elm-land.elm-land
        #posit.air-vscode
        #github.copilot
        #databricks.databricks
        #esbenp.prettier-vscode
        #ms-python.python
        # Required by hbenl.vscode-test-explorer
        ms-vscode.test-adapter-converter
        #reditorsupport.r
        #reditorsupport.r-syntax
        elmtooling.elm-ls-vscode
        #redhat.vscode-yaml
        esbenp.prettier-vscode
        #tomoki1207.pdf
        # dependency of elm extension
        hbenl.vscode-test-explorer
        #quarto.quarto
        vscodevim.vim
        myriad-dreamin.tinymist
        #vspacecode.vspacecode
        #vspacecode.whichkey
        #ms-vscode.powershell
      ];
    };
  };
}
