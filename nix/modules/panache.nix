{
  config,
  lib,
  pkgs,
  ...
}:
let
  configPath = "${config.xdg.configHome}/panache/config.toml";
in
{
  options.jls.panache = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The configured Panache package.";
    };
    configPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The path to the shared Panache configuration.";
    };
  };

  config = {
    jls.panache = {
      package = pkgs.panache;
      inherit configPath;
    };

    home.packages = [ config.jls.panache.package ];

    xdg.configFile."panache/config.toml".source = ../../panache/panache.toml;

    home.sessionVariables.PANACHE_CONFIG = config.jls.panache.configPath;
  };
}
