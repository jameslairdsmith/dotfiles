{ pkgs, ... }:
let
  dotsDir = ../..;
  vscodeConfigDir = "Library/Application Support/Code/User";
in
{
  home.file = {
    "${vscodeConfigDir}/keybindings.json".source = "${dotsDir}/vscode/keybindings.json";
    "${vscodeConfigDir}/settings.json".source = "${dotsDir}/vscode/settings.json";
  };

  programs.vscode = {
    enable = true;

    argvSettings = {
      enable-crash-reporter = false;
    };

    profiles.default = {
      # Changed to using dedicated settings.json because it also works on Windows.
      /*
           userSettings = {
          "update.mode" = "none";
        };
      */
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
