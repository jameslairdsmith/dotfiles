{ ... }:
{
  home.shellAliases = {
    gs = "git status";
    gcl = "git clone --recurse-submodules";
    gch = "git checkout";
    gc = "git commit";
    gd = "git diff";
    ga = "git add";
  };

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
