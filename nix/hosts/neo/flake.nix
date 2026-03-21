{
  description = "JLS nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {

          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.neovim
            #pkgs.alacritty
            pkgs.brave
            pkgs.google-chrome
            pkgs.ghostty-bin
            pkgs.fish
            #pkgs.mullvad-vpn
            pkgs.git
            pkgs.obsidian
          ];

          programs.fish.enable = true;

          environment.shells = [
            pkgs.fish
          ];

          users.users.jls.shell = pkgs.fish;

          homebrew = {
            enable = true;
            brews = [
              "mas"
            ];
            casks = [
              # "firefox"
            ];
            masApps = {
              #"Yoink" = 457622435;
              "ExpressVPN" = 886492891;
            };
            onActivation.cleanup = "zap";
          };

          fonts.packages = [
            #(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
            pkgs.nerd-fonts.jetbrains-mono
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          system.primaryUser = "jls";

          users.users.jls.home = "/Users/jls";

          system.defaults = {
            dock.autohide = true;
            trackpad.TrackpadThreeFingerDrag = true;
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."neo" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration

          #services.mullvad-vpn.enable = true;

          #({ pkgs, ... }: {
          # This is the line that was failing.
          # It MUST be inside this top-level modules list.
          #  services.mullvad-vpn.enable = true;

          # Allow the CLI to be available globally
          #  environment.systemPackages = [ pkgs.mullvad ];
          #})

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            #home-manager.users.jls = import "/Users/jls/.config/home-manager/home.nix";
            home-manager.users.jls = import ./home.nix;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "jls";
            };
          }
        ];
      };
    };
}
