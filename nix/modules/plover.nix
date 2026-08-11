{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.plover-flake.homeManagerModules.plover
  ];

  # home.file."Library/Application Support/plover/plover.cfg".source =
  #   ../../plover/plover.cfg;

  programs.plover = {
    enable = true;
    package = inputs.plover-flake.packages.${pkgs.stdenv.hostPlatform.system}.plover.withPlugins (
      ps: with ps; [
        plover-python-dictionary
        plover-modal-dictionary
        plover-dict-commands
        plover-last-translation
        plover-stitching
      ]
    );

    # settings = {
    #   "Machine Configuration" = {
    #     machine_type = "Gemini PR";
    #     auto_start = true;
    #   };
    #   "System: Lapwing".dictionaries = [
    #     {
    #       enabled = true;
    #       path = "~/projects/steno/src-dicts/emily-modifiers.py";
    #     }
    #   ]; # doesn't work
    #   "Output Configuration".undo_levels = 100;
    # };
  };
}
