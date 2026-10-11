{
  config,
  inputs,
  pkgs,
  ...
}:
let
  r-nvim = inputs.r-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      pkgs.nodejs
      pkgs.tree-sitter
    ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lua/r/config.lua \
        --replace-fail "mt2 > mt1" "mt2 >= mt1"
    '';
    buildPhase = (old.buildPhase or "") + ''
      export HOME="$TMPDIR"
      pushd resources/tree-sitter-rout
      tree-sitter generate
      mkdir -p ../../parser
      tree-sitter build -o ../../parser/rout.so
      popd
    '';
  });
  focal-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "focal.nvim";
    version = "unstable-2026-04-05";
    src = pkgs.fetchFromGitHub {
      owner = "hmdfrds";
      repo = "focal.nvim";
      rev = "25c946b9ba57c394fbb8644f084a4cd6d0004e54";
      hash = "sha256-tlTN4RTsKnj2TiSEM+OfMs02zS92P/jy7qK0LvmsFfI=";
    };
  };
  modusThemeSetup = ''
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
in
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  xdg.configFile."nvcat/init.lua".text = ''
    vim.opt.rtp:append("${pkgs.vimPlugins.modus-themes-nvim}")
    vim.opt.rtp:append("${pkgs.vimPlugins.auto-dark-mode-nvim}")
    ${modusThemeSetup}
  '';

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

      treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
        csv
        latex
        markdown
        markdown_inline
        r
        rnoweb
        typst
        yaml
      ];

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

      extraPackages = [
        config.jls.r.package
        pkgs.chafa
        pkgs.clang
        pkgs.gnumake
        pkgs.tree-sitter
      ];

      extraPlugins = {
        r-nvim = {
          package = r-nvim;
          setup = ''
            require("r").setup({
              R_app = "${config.jls.r.package}/bin/R",
              R_cmd = "${config.jls.r.package}/bin/R",
              Rout_follow_colorscheme = true,
            })
          '';
        };
        modus-themes.package = pkgs.vimPlugins.modus-themes-nvim;
        auto-dark-mode = {
          package = pkgs.vimPlugins.auto-dark-mode-nvim;
          setup = modusThemeSetup;
        };
        oil-nvim = {
          package = pkgs.vimPlugins.oil-nvim;
          setup = ''
            require("oil").setup({
              keymaps = {
                ["z"] = {
                  callback = function()
                    local oil = require("oil")
                    local entry = oil.get_cursor_entry()

                    if entry and entry.type == "directory" then
                      oil.select()
                    else
                      oil.open()
                    end
                  end,
                  desc = "Enter directory or go to parent",
                },
              },
            })

            vim.api.nvim_create_autocmd("FileType", {
              pattern = "oil",
              callback = function(args)
                vim.keymap.set("n", "q", "<Cmd>quit<CR>", {
                  buffer = args.buf,
                  desc = "Close Oil",
                })
              end,
            })
          '';
        };
        mini-files = {
          package = pkgs.vimPlugins.mini-files;
          setup = ''
            require("mini.files").setup()

            vim.api.nvim_create_autocmd("User", {
              pattern = "MiniFilesExplorerClose",
              callback = function()
                if vim.g.mini_files_standalone then
                  vim.schedule(function()
                    vim.cmd("quitall")
                  end)
                end
              end,
            })
          '';
        };
        focal-nvim = {
          package = focal-nvim;
          setup = ''
            vim.o.updatetime = 300

            require("focal").setup({
              backend = "chafa",
            })
          '';
        };
      };
    };
  };
}
