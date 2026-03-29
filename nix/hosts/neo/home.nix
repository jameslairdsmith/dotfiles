{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "jls";
  home.homeDirectory = "/Users/jls";
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    hello
    tmux
    nixfmt
    alejandra
    nixd
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

  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
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

  programs.vscode = {
    enable = true;

    argvSettings = {
      enable-crash-reporter = false;
    };

    profiles.default = {
      userSettings = {
        "update.mode" = "none";
      };
      extensions = with pkgs.vscode-marketplace; [
        jnoortheen.nix-ide # Nix language support + formatting
        sourcegraph.amp
        #posit.air-vscode
        #github.copilot
        #databricks.databricks
        #esbenp.prettier-vscode
        #ms-python.python
        #reditorsupport.r
        #reditorsupport.r-syntax
        #elmtooling.elm-ls-vscode
        #elm-land.elm-land
        #redhat.vscode-yaml
        #tomoki1207.pdf
        #quarto.quarto
        vscodevim.vim
        #vspacecode.vspacecode
        #vspacecode.whichkey
        #ms-vscode.powershell
      ];
    };
  };

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
    settings.command = "/run/current-system/sw/bin/fish";
    # Need this until pkgs.ghostty works on Mac
    #package = pkgs.ghostty-bin;
    package = null;
    #enableBashIntegration = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      gs = "git status";
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      gs = "git status";
      hr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      gs = "git status";
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

  #programs.git = {
  #  enable = true;
  #  settings = {
  #    userName = "James Laird-Smith";
  #    userEmail = "jameslairdsmith@gmail.com";
  #  };
  #  aliases = {
  #    gs = "git status";
  #  };
  #};
}
