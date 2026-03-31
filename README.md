# dotfiles

These are my dotfile

## Nix

Nix configuration files live in the "nix/" directory. But many of the
configuration files there use other files in the repo. Whether to change a 
setting using Nix or with a tool specific configuration (like settings.json for 
VS Code) is a preference which varies from tool-to-tool. In general, if there
is a dedicated non-nix config file in this repo, the Nix config will use that; if 
there is no such file, then the preference is to set it from Nix. 
 
# Shells

Multiple shells configs are represented their respective directories; for 
example bash/ zsh/ and fish/. These are not usually used directly, but rather
through "home.nix". Much of the content is duplicated with an attempt to give 
them similar capabilities and user experience.