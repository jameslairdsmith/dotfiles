{
  config,
  pkgs,
  ...
}:
let
  json = pkgs.formats.json { };
in
{
  home.packages = [
    pkgs.positron-bin
  ];

  home.file."Library/Application Support/Positron/User/settings.json" = {
    force = true;
    source = json.generate "positron-settings.json" {
      "files.associations" = {
        "renv.lock" = "json";
      };
      "positron.r.customBinaries" = [
        "${config.jls.r.unwrappedPackage}/bin/R"
      ];
      "positron.r.kernel.env".R_LIBS_SITE = config.jls.r.libraryPath;
    };
  };
}
