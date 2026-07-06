{
  pkgs,
  ...
}:
let
  dotsDir = ../..;

  # Pinned revision of the upstream pi repo used to fetch single-file
  # extensions from its examples/ directory.
  piRev = "ee24a9ec54a9602d55dc7ac767c270cec806c291";

  # Syncs the pi theme with the macOS system appearance (dark/light). A
  # single-file extension with no runtime dependencies, so it can be dropped
  # straight into ~/.pi/agent/extensions/ and loaded by jiti as-is.
  macSystemTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/earendil-works/pi/${piRev}/packages/coding-agent/examples/extensions/mac-system-theme.ts";
    hash = "sha256-1zSbrpmaeYxxsoMWXgbQFC1BsCZL/a0R3cseyLYvhxA=";
  };
in
{
  programs.pi-coding-agent = {
    enable = true;

    # Global settings, hand-editable in pi/settings.json.
    settings = builtins.fromJSON (builtins.readFile "${dotsDir}/pi/settings.json");

    # Global instructions (~/.pi/agent/AGENTS.md). Reuse the shared agent
    # instructions so pi and amp stay in sync.
    context = ../../agents/AGENTS.md;
  };

  # Single-file extensions are not covered by the module option; drop them
  # straight into ~/.pi/agent/extensions/ for auto-discovery.
  home.file.".pi/agent/extensions/mac-system-theme.ts".source = macSystemTheme;
}
