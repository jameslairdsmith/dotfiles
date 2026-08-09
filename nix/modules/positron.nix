{
  config,
  pkgs,
  ...
}:
let
  dotsDir = ../..;
  json = pkgs.formats.json { };
  generalSettings = builtins.fromJSON (builtins.readFile "${dotsDir}/positron/settings.json");
  nixSettings = {
    "positron.r.customBinaries" = [
      "${config.jls.r.unwrappedPackage}/bin/R"
    ];
    "positron.r.kernel.env".R_LIBS_SITE = config.jls.r.libraryPath;
  };
in
{
  home.packages = [
    pkgs.positron-bin
  ];

  home.file."Library/Application Support/Positron/User/settings.json" = {
    force = true;
    source = json.generate "positron-settings.json" (generalSettings // nixSettings);
  };
}
