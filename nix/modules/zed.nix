{
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "opencode"
      "org"
      "r"
      "quarto"
      "elisp"
      "elm"
      "modus-themes"
      "typst"
    ];
    userSettings = {
      agent_servers = {
        amp-acp = {
          type = "registry";
        };
        opencode = {
          type = "registry";
        };
      };
      buffer_font_family = "JetBrainsMono Nerd Font";
      terminal = {
        dock = "right";
        font_family = "JetBrainsMono Nerd Font";
      };
      project_panel = {
        hide_hidden = false;
        hide_root = false;
        sticky_scroll = false;
        bold_folder_labels = false;
        auto_fold_dirs = true;
        starts_open = false;
        indent_size = 20.0;
        folder_icons = false;
        dock = "left";
      };
      agent = {
        dock = "right";
        sidebar_side = "right";
        favorite_models = [ ];
        model_parameters = [ ];
      };
      outline_panel = {
        file_icons = true;
        button = false;
        dock = "left";
      };
      theme = {
        mode = "system";
        dark = "One Dark";
        light = "One Light";
      };
      icon_theme = {
        mode = "system";
        light = "Zed (Default)";
        dark = "Zed (Default)";
      };
      hour_format = "hour24";
      auto_update = false;
      vim_mode = true;
    };
  };
}
