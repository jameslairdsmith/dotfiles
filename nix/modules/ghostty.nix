{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      command = "/run/current-system/sw/bin/fish";
      keybind = [
        "performable:super+c=copy_to_clipboard:mixed"
        "super+s=unbind"
      ];
      # Previous light themes:
      # - Modus Operandi
      # - Bluloco Light
      theme = "dark:Modus Vivendi,light:One Double Light";
      font-size = 16;
      # Set the internal margins (adjust the numbers to your liking)
      window-padding-x = 20;
      window-padding-y = 20;
      # Distribute the "extra" space evenly to centre the text grid
      window-padding-balance = true;
    };
    # Need this until pkgs.ghostty works on Mac
    # package = pkgs.ghostty-bin;
    package = null;
    # enableBashIntegration = true;
  };
}
