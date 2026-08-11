{
  config,
  pkgs,
  ...
}:
let
  treefmtConfig = "${config.home.homeDirectory}/.config/treefmt/treefmt.toml";
in
{
  home.packages = [ pkgs.treefmt ];

  home.file.".config/treefmt/treefmt.toml".source = ../../treefmt/treefmt.toml;

  # Use the shared config when a project does not provide TREEFMT_CONFIG
  # itself. Current treefmt versions still infer the tree root from Git.
  home.sessionVariables.TREEFMT_CONFIG = treefmtConfig;
}
