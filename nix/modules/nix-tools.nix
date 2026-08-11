{ pkgs, ... }:
{
  home.packages = with pkgs; [
    alejandra
    nixd
    nixfmt
  ];
}
