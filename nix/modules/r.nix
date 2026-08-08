{
  lib,
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
  rPackages = pkgs.lib.remove pkgs.R (pkgs.lib.closePropagation myR.buildInputs);
  rLibsSite = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/library") rPackages;
  arf = inputs.arf.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/arf \
        --suffix PATH : ${pkgs.lib.makeBinPath [ myR ]} \
        --prefix R_LIBS_SITE : "${rLibsSite}"
    '';
  });
in
{
  options.jls.r = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The configured R runtime and package environment.";
    };
    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The underlying unwrapped R installation.";
    };
    libraryPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The R package library search path.";
    };
  };

  config = {
    jls.r.package = myR;
    jls.r.unwrappedPackage = pkgs.R;
    jls.r.libraryPath = rLibsSite;

    home.packages = [
      myR
      arf
    ];

    home.file.".config/arf/arf.toml".source = "${dotsDir}/arf.toml";
  };
}
