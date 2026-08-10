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
    "nix.formatterPath" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings".nixd.formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
    "positron.r.customBinaries" = [
      "${config.jls.r.unwrappedPackage}/bin/R"
    ];
    "positron.r.kernel.env".R_LIBS_SITE = config.jls.r.libraryPath;
  };

  panacheExtension = pkgs.vscode-utils.buildVscodeExtension {
    pname = "jolars-panache";
    version = "3.3.0";
    src = pkgs.fetchurl {
      url = "https://open-vsx.org/api/jolars/panache/darwin-arm64/3.3.0/file/jolars.panache-3.3.0@darwin-arm64.vsix";
      hash = "sha256-7sU3XqX7I4rFZiQSLp0SwZeBFVivBsx+tCNQr5x59nA=";
    };
    vscodeExtPublisher = "jolars";
    vscodeExtName = "panache";
    vscodeExtUniqueId = "jolars.panache";
  };

  # Positron has no Home Manager extension option. Add packages here and
  # expose each one in Positron's normal extension directory, preserving
  # Positron's bundled and mutable extensions alongside the Nix-managed ones.
  extensions = with pkgs.vscode-extensions; [
    esbenp.prettier-vscode
    jnoortheen.nix-ide
    panacheExtension
    databricks.databricks
    vscodevim.vim
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
