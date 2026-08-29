{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      lsp.enable = true;
      lsp.formatOnSave = true;
      lsp.servers.nixd.settings.nixd.formatting.command = [ "nixfmt" ];
      lsp.servers.nixd.settings.nixd.nixpkgs.expr = ''
        let
          flake = builtins.getFlake "git+file:///Users/jls/projects/dotfiles?dir=nix/hosts/neo";
        in
        import flake.inputs.nixpkgs {
          system = "aarch64-darwin";
                        config.allowUnfree = true;
          overlays = [ flake.inputs.nix-vscode-extensions.overlays.default ];
        }
      '';
      lsp.servers.nixd.settings.nixd.options.home-manager.expr = ''
        (builtins.getFlake
          "git+file:///Users/jls/projects/dotfiles?dir=nix/hosts/neo")
          .homeConfigurations.jls.options
      '';
      lsp.servers.nixd.settings.nixd.options.nix-darwin.expr = ''
        (builtins.getFlake
          "git+file:///Users/jls/projects/dotfiles?dir=nix/hosts/neo")
          .darwinConfigurations.neo.options
      '';
      languages = {
        enableTreesitter = true;
        nix = {
          enable = true;
          lsp.servers = [ "nixd" ];
        };
        r.enable = true;
        elm.enable = true;
      };

      statusline.lualine.enable = true;
      telescope.enable = true;
      autocomplete.nvim-cmp.enable = true;

      keymaps = [
        {
          mode = [
            "n"
            "i"
            "x"
          ];
          key = "<D-s>";
          action = "<Cmd>write<CR>";
          desc = "Save file";
        }
        {
          mode = "x";
          key = "<D-c>";
          action = ''"+y'';
          desc = "Copy selection to system clipboard";
        }
      ];

      # extraPackages = with pkgs.elmPackages; [
      #   elm
      #   elm-format
      #   elm-test
      # ];

      extraPlugins = {
        modus-themes.package = pkgs.vimPlugins.modus-themes-nvim;
        auto-dark-mode = {
          package = pkgs.vimPlugins.auto-dark-mode-nvim;
          setup = ''
            require("auto-dark-mode").setup({
              set_light_mode = function()
                vim.o.background = "light"
                vim.cmd.colorscheme("modus_operandi")
              end,
              set_dark_mode = function()
                vim.o.background = "dark"
                vim.cmd.colorscheme("modus_vivendi")
              end,
            })
          '';
        };
      };
    };
  };
}
