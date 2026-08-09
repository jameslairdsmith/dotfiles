{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotsDir = ../..;
  json = pkgs.formats.json { };

  # Keep portable, hand-editable settings in JSON. Nix-derived values are
  # merged afterwards so they take precedence if a key appears in both sets.
  generalSettings = builtins.fromJSON (builtins.readFile "${dotsDir}/positron/settings.json");
  nixSettings = {
    "positron.r.customBinaries" = [
      "${config.jls.r.unwrappedPackage}/bin/R"
    ];
    "positron.r.kernel.env".R_LIBS_SITE = config.jls.r.libraryPath;
  };

  # Positron has no Home Manager extension option. Add packages here and
  # expose each one in Positron's normal extension directory, preserving
  # Positron's bundled and mutable extensions alongside the Nix-managed ones.
  extensions = with pkgs.vscode-extensions; [
    esbenp.prettier-vscode
    jnoortheen.nix-ide
  ];
  extensionFiles = builtins.listToAttrs (
    map (extension: {
      name = ".positron/extensions/${extension.vscodeExtUniqueId}-${extension.version}";
      value.source = "${extension}/share/vscode/extensions/${extension.vscodeExtUniqueId}";
    }) extensions
  );
in
{
  home.packages = [
    pkgs.positron-bin
  ];

  home.file = extensionFiles // {
    "Library/Application Support/Positron/User/settings.json" = {
      force = true;
      source = json.generate "positron-settings.json" (generalSettings // nixSettings);
    };
  };

  # Positron does not notice extensions added by Home Manager while its
  # generated cache exists. It rebuilds the cache on the next launch.
  home.activation.refreshPositronExtensionCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD rm -f "$HOME/.positron/extensions/extensions.json"
  '';
}
