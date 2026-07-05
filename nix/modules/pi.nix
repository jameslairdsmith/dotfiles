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
  home.packages = [
    pkgs.pi-coding-agent
  ];

  # Pi loads global instructions from ~/.pi/agent/AGENTS.md. Reuse the shared
  # agent instructions so pi and amp stay in sync.
  home.file.".pi/agent/AGENTS.md".source = "${dotsDir}/agents/AGENTS.md";

  # Global pi settings live in the repo's pi/ folder. Individual files are
  # symlinked (not the whole directory) so pi can still write sessions, auth,
  # and installed packages into ~/.pi/agent/.
  home.file.".pi/agent/settings.json".source = "${dotsDir}/pi/settings.json";

  # Single-file extensions, auto-discovered from ~/.pi/agent/extensions/.
  home.file.".pi/agent/extensions/mac-system-theme.ts".source = macSystemTheme;
}
