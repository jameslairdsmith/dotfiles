{
  pkgs,
  inputs,
  ...
}:
let
  dotsDir = ../..;
  myR = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      tidyverse
      languageserver
      devtools
      usethis
      tidymodels
      data_table
    ];
  };
  rLibsSite = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/library") myR.buildInputs;
  arf = inputs.arf.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/arf \
        --suffix PATH : ${pkgs.lib.makeBinPath [ myR ]} \
        --prefix R_LIBS_SITE : "${rLibsSite}"
    '';
  });
in
{
  home.packages = [
    myR
    arf
  ];

  home.file.".config/arf/arf.toml".source = "${dotsDir}/arf.toml";
}
