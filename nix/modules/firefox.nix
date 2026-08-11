{ pkgs, ... }:
{
  # nixpkgs-firefox-darwin looks more promising
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
}
