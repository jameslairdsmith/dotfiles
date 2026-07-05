{
  pkgs,
  ...
}:
{
  # treefmt plus the formatters it drives. They need to be on PATH because a
  # treefmt config references them by command name.
  #
  # The config itself lives at treefmt/treefmt.toml in this repo and is used as
  # a template: copy it into a project root as treefmt.toml. treefmt then
  # discovers it by walking upward from the working directory.
  home.packages = with pkgs; [
    treefmt
    nixfmt
    prettier
  ];
}
