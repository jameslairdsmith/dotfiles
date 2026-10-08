{
  config,
  pkgs,
  inputs,
  ...
}:
let
  dotsDir = ../..;
  system = pkgs.stdenv.hostPlatform.system;

  # Tracks nixpkgs-unstable independently so pi-coding-agent can be bumped
  # without updating every other package pinned by the main nixpkgs input.
  # Update with: nix flake lock --update-input nixpkgs-pi-coding-agent
  piCodingAgentPackage =
    (import inputs.nixpkgs-pi-coding-agent {
      inherit system;
      config.allowUnfree = true;
    }).pi-coding-agent;

  bun2nix = inputs.bun2nix.packages.${system}.default;

  piWebAccess = pkgs.callPackage ../../pi/packages/pi-web-access {
    inherit bun2nix;
  };

  piSubagents = pkgs.callPackage ../../pi/packages/pi-subagents {
    inherit bun2nix;
  };

  mcpReplAsset =
    {
      aarch64-darwin = {
        name = "mcp-repl-aarch64-apple-darwin";
        hash = "sha256-MSHGjAqjiGPg96ouJly2e41rQSj2gGVOUxV+GOR019Y=";
      };
    }
    .${system} or (throw "posit-mcp-repl is not packaged for ${system} in this dotfiles module");

  mcpReplPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "posit-mcp-repl";
    version = "0.3.0";

    src = pkgs.fetchurl {
      url = "https://github.com/posit-dev/mcp-repl/releases/download/v0.3.0/${mcpReplAsset.name}.tar.gz";
      inherit (mcpReplAsset) hash;
    };

    installPhase = ''
      runHook preInstall

      install -Dm755 mcp-repl $out/bin/mcp-repl
      install -Dm644 LICENSE $out/share/licenses/posit-mcp-repl/LICENSE
      install -Dm644 README.md $out/share/doc/posit-mcp-repl/README.md

      runHook postInstall
    '';
  };

  mcpRepl = pkgs.writeShellApplication {
    name = "mcp-repl";
    runtimeInputs = [
      mcpReplPackage
      config.jls.r.package
    ];
    text = ''
      exec ${mcpReplPackage}/bin/mcp-repl "$@"
    '';
  };

  piMcpConfig = (pkgs.formats.json { }).generate "pi-mcp.json" {
    mcpServers = {
      r = {
        command = "${mcpRepl}/bin/mcp-repl";
        args = [
          "--sandbox"
          "workspace-write"
          "--oversized-output"
          "files"
          "--interpreter"
          "r"
        ];
        env = {
          R_LIBS_SITE = config.jls.r.libraryPath;
        };
        exposure = "direct";
        timeout = 1800;
      };

    };
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

  home.file.".pi/agent/extensions/exit-alias".source = ../../pi/extensions/exit-alias;
  home.file.".pi/agent/mcp.json".source = piMcpConfig;
  home.file.".pi/agent/packages/pi-web-access".source = piWebAccess;
  home.file.".pi/agent/packages/pi-subagents".source = piSubagents;
}
