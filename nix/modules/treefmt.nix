{
  pkgs,
  inputs,
  ...
}:
let
  # Build a self-contained treefmt wrapper that bundles its config and the
  # formatters below. Installing the wrapper gives a `treefmt` command that
  # already knows how to format Nix and Markdown.
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    # Nix files are formatted with nixfmt (see AGENTS.md).
    programs.nixfmt.enable = true;

    # Markdown formatted with Prettier (prose wrap always, print width 80).
    programs.prettier = {
      enable = true;
      settings = {
        proseWrap = "always";
        printWidth = 80;
      };
    };
  };
in
{
  home.packages = [ treefmtEval.config.build.wrapper ];
}
