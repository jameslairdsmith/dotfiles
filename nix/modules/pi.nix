{
  pkgs,
  inputs,
  ...
}:
let
  dotsDir = ../..;

  # Tracks nixpkgs-unstable independently so pi-coding-agent can be bumped
  # without updating every other package pinned by the main nixpkgs input.
  # Update with: nix flake lock --update-input nixpkgs-pi-coding-agent
  piCodingAgentPackage =
    (import inputs.nixpkgs-pi-coding-agent {
      system = pkgs.system;
      config.allowUnfree = true;
    }).pi-coding-agent;

  piWebAccess = pkgs.callPackage ../../pi/packages/pi-web-access {
    bun2nix = inputs.bun2nix.packages.${pkgs.system}.default;
  };

in
{
  programs.pi-coding-agent = {
    enable = true;
    package = piCodingAgentPackage;

    # Global settings, hand-editable in pi/settings.json.
    settings = builtins.fromJSON (builtins.readFile "${dotsDir}/pi/settings.json");

    # Global instructions (~/.pi/agent/AGENTS.md). Reuse the shared agent
    # instructions so pi and amp stay in sync.
    context = ../../agents/AGENTS.md;
  };

  home.file.".pi/agent/extensions/exit-alias.ts".source = ../../pi/extensions/exit-alias.ts;
  home.file.".pi/agent/packages/pi-web-access".source = piWebAccess;
}
