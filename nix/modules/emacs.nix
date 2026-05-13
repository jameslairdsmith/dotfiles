{
  pkgs,
  ...
}:
{
  programs.emacs = {
    enable = true;
    extraPackages =
      epkgs: with epkgs; [
        use-package
        magit
      ];
  };
}
