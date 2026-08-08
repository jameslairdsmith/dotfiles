# Dotfiles repo — agent instructions

Instructions specific to working in this repository. My general, cross-project
preferences (British English, Nix-first, git workflow, skills, learning mode)
live in `agents/AGENTS.md` and are loaded globally by my agents — Amp reads it as
`~/.config/amp/AGENTS.md`, and pi loads it as its `~/.pi/agent/AGENTS.md`
context. Read that file for how I like to work in general; this file is only
about the repo itself.

## What this repo is

My personal dotfiles, managed with Nix (nix-darwin + Home Manager) on macOS
(Apple Silicon). The active host is `neo`.

## Layout

- `nix/hosts/neo/` — the nix-darwin + Home Manager flake for this machine.
  - `flake.nix` — the real system flake (the `neo` darwinConfiguration).
  - `home.nix` — Home Manager config; imports the modules below.
- `nix/modules/` — per-topic Home Manager modules (e.g. `emacs.nix`, `pi.nix`,
  `r.nix`, `zed.nix`, `treefmt.nix`), imported from `home.nix`.
- Per-tool folders (`fish/`, `zsh/`, `bash/`, `emacs/`, `vscode/`, `pi/`, `R/`,
  `plover/`, …) hold non-Nix config files that the Nix config references.
- `agents/AGENTS.md` — my general, cross-project agent config (see above).
- The root `flake.nix` is only a dev shell, not the system config.

## Config convention

If a tool has a dedicated non-Nix config file in this repo, the Nix config
references that file; if there is no such file, set the option from Nix instead.
See `README.md`.

## Building and applying

- Apply the system: `hr` (alias for
  `sudo darwin-rebuild switch --flake ~/projects/dotfiles/nix/hosts/neo#neo`).
- Check a change builds without switching:
  `darwin-rebuild build --flake ./nix/hosts/neo#neo`. Prefer this to verify.
- **Flakes only see git-tracked files.** After creating a new file, `git add` it
  (no commit needed) before building, or Nix will not find it.

## Formatting

- Nix files: `nixfmt` (language server: `nixd`).
- treefmt config is a template at `treefmt/treefmt.toml`; copy it into a project
  root to use it there.
