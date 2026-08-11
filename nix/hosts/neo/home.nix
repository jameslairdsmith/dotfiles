{
  config,
  pkgs,
  inputs,
  ...
}:
let
  dotsDir = ../../..;
in
{
  imports = [
    ../../modules/emacs.nix
    ../../modules/plover.nix
    ../../modules/r.nix
    ../../modules/positron.nix
    ../../modules/zed.nix
    ../../modules/vscode.nix
    ../../modules/treefmt.nix
    ../../modules/pi.nix
  ];

  home.username = "jls";
  home.homeDirectory = "/Users/jls";
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    hello
    tmux
    nixfmt
    opencode
    alejandra
    nixd
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.writeShellScriptBin "wt-clone" ''
      set -e
      url="$1"
      repo_name="$(basename "$url" .git)"
      mkdir -p "$repo_name"
      git clone --bare "$url" "$repo_name/.bare"
      echo "gitdir: ./.bare" > "$repo_name/.git"
      git -C "$repo_name" config remote.origin.fetch \
        "+refs/heads/*:refs/remotes/origin/*"
      git -C "$repo_name" fetch origin
      default_branch="$(git -C "$repo_name" symbolic-ref --short HEAD)"
      git -C "$repo_name" branch \
        --set-upstream-to="origin/$default_branch" "$default_branch"
    '')
    amp-cli
    onefetch
    zoom-us
    # Using VS Code extension's bundled version of prettier for now
    #prettier
    #ghostty-bin
    #fish
    #pkgs.alacritty
    #pkgs.qbittorrent

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.shellAliases = {
    gs = "git status";
    gcl = "git clone --recurse-submodules";
    gch = "git checkout";
    gc = "git commit";
    gd = "git diff";
    ga = "git add";
  };

  home.file = {
    ".config/worktrunk/config.toml".source = "${dotsDir}/worktrunk/config.toml";
    ".config/amp/AGENTS.md".source = "${dotsDir}/agents/AGENTS.md";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jls/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    #SHELL = "bash";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # nixpkgs-firefox-darwin looks more promising

  /*
       programs.firefox = {
      enable = true;
      profiles.jls = {
        isDefault = true;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
        ];
        settings = {
          "browser.startup.homepage" = "https://www.google.com";
        };
      };
    };
  */

  programs.ghostty = {
    enable = true;
    settings = {
      command = "/run/current-system/sw/bin/fish";
      keybind = [
        "performable:super+c=copy_to_clipboard:mixed"
      ];
      theme = "dark:Modus Vivendi,light:Modus Operandi";
      font-size = 16;
      # Set the internal margins (adjust the numbers to your liking)
      window-padding-x = 20;
      window-padding-y = 20;
      # Distribute the "extra" space evenly to center the text grid
      window-padding-balance = true;
    };
    # Need this until pkgs.ghostty works on Mac
    #package = pkgs.ghostty-bin;
    package = null;
    #enableBashIntegration = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile "${dotsDir}/fish/config.fish";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.zsh = {
    enable = true;
    initContent = builtins.readFile "${dotsDir}/zsh/zshrc";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.bash = {
    enable = true;
    profileExtra = builtins.readFile "${dotsDir}/bash/bash-profile";
    shellAliases = {
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  /*
        programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
      commandLineArgs = [
        "--disable-features=WebRtcAllowInputVolumeAdjustment"
      ];
    };
  */

  programs.git = {
    enable = true;
    settings = {
      user.name = "James Laird-Smith";
      user.email = "jameslairdsmith@gmail.com";
      submodule.recurse = true;
      diff.submodule = "log";
      push.recurseSubmodules = "check";
      status.submoduleSummary = true;
    };
  };
}
