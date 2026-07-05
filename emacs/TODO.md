# Emacs config TODO

A running list of things to do, decide, or revisit for the fresh Emacs config.
Captured from the rebuild thread. Roughly ordered: open decisions first, then
the planned build-out, then enhancements and ideas.

## Open decisions (needed before some steps)

- [ ] **Completion stack** — choose between the familiar
      `ivy`/`counsel`/`swiper` stack (from the old config) and the modern
      `vertico` + `consult` + `marginalia` + `orderless` stack. Drives several
      keybindings below.
- [ ] **Evil / Vim emulation** — keep `evil` + `evil-collection` (was present
      but commented out in the old config) or stay with vanilla Emacs bindings.
- [ ] **Modeline** — the old config used `doom-modeline`. Decide: keep it, use a
      lighter option, or stick with the built-in modeline (Modus styles it
      cleanly already).
- [ ] **Line numbers** — re-add `column-number-mode` and
      `global-display-line-numbers-mode` (with the per-mode disable for org,
      term, shell and eshell), or leave them off. Removed during Step 2a.

## Planned build-out (next steps)

- [ ] **Completion stack** — implement once decided (see above).
- [ ] **R / ESS** — port the old setup: `ess-r-mode`, `company` (script-only),
      `company-R-args`, `ess-rdired` on a key, the `display-buffer-alist` window
      layout for `*R*`/`*R Dired*`/`*Help*`, and disable `ess-use-flymake`. Wire
      the R binary from `r.nix` the Nix way (inject its store path via
      `nix-paths.el` rather than relying on PATH).
- [ ] **Magit** — add via Nix `extraPackages` and configure.
- [ ] **Org mode** — minimal config for notes/capture. (Decided against the old
      literate/`org-transclusion` tangling workflow.)
- [ ] **which-key** — discoverability for prefixes; was in the old config.
- [ ] **helpful** — nicer `*Help*` buffers; was in the old config.
- [ ] **Project management** — decide built-in `project.el` vs `projectile` (+
      the old R-project detection / open-project helpers).
- [ ] **rainbow-delimiters** — from the old config, for prog modes.

## Restore / rebind (deferred from earlier steps)

- [ ] `s-f` → find file (or completion-aware equivalent once the stack is
      chosen).
- [ ] `s-b` → switch buffer (was `counsel-switch-buffer`).
- [ ] `s-D` → dired in the current directory (`jls/open-dired-local`).
- [ ] `s-t` → choose/load theme (was `counsel-load-theme`).

## Enhancements / ideas

- [ ] **Theme follows macOS appearance** — auto-switch Modus light/dark with the
      system setting using the Mac port's
      `ns-system-appearance-change-functions` (operandi for light, vivendi for
      dark). Mirrors the Ghostty config
      (`dark:Modus Vivendi, light:Modus Operandi`). Currently a manual choice.
- [ ] **Lower GC after startup** — `early-init.el` raises `gc-cons-threshold` to
      64 MiB but never lowers it. Reset it (or a sensible value) after init, or
      adopt `gcmh`.
- [ ] **Font** — the old config used Fira Code (with ligatures). Decide on a
      font and provide it via Nix (a font package) rather than assuming it's
      installed.
- [ ] **Extend the save dispatch** — `jls/save-buffer` dispatches on major mode;
      add savers/formatters for other languages (e.g. Nix via `nixfmt` or
      `alejandra`, R, etc.), each wired the Nix way. Alternatively evaluate
      `apheleia` as a unified async format-on-save framework instead of the
      bespoke dispatch.
- [ ] **CLI elisp formatter** — wrap a batch invocation of
      `elisp-autofmt-buffer-to-file` in a Nix `writeShellScriptBin` (e.g.
      `fmt-elisp`) so elisp can be formatted from the command line / CI, reusing
      the sequestered Python via `--load ~/.config/emacs/nix-paths.el`.
- [ ] **Dashboard icons** — enable icons on the startup dashboard by adding
      `nerd-icons` (Nix `extraPackages`), running `nerd-icons-install-fonts`,
      and setting `dashboard-set-heading-icons`/`dashboard-set-file-icons` to
      `t` (both default to `nil`). Currently the dashboard runs icon-free.
- [ ] **elisp-autofmt options** — explore its config (line length, etc.) and
      whether a `.elisp-autofmt` file is wanted; currently `on-save-p` is
      `'always`.
- [ ] **Lockfiles / auto-save** — backups are disabled
      (`make-backup-files nil`). Decide on `create-lockfiles` (`.#file`) and
      auto-save (`#file#`) too.
- [ ] **menu-bar** — currently keeping the macOS native menu bar; revisit if not
      wanted.
- [ ] **eat `eat-term-name` set to `xterm-256color`** — eat defaults
      `eat-term-name` to `eat-truecolor`, but the Nix `eat` package ships that
      terminfo entry compiled by Nix's ncurses 6 in the 32-bit extended-number
      format, which Apple's ancient system ncurses (used by `/usr/bin/top`,
      system `vi`, etc.) can't read — giving
      `Error opening terminal:     eat-truecolor`. Worked around by setting
      `(eat-term-name "xterm-256color")` (a type both Apple's and Nix's terminfo
      databases know), at the cost of losing eat's `Tc` truecolor advertisement
      (programs fall back to a 256-colour palette). Revisit if 24-bit colour
      matters: either use Nix-built curses tools (e.g. `htop`) instead of
      Apple's, or recompile eat's terminfo in legacy 16-bit format into a path
      Apple reads (fiddly — Nix `tic` emits 32-bit). Amp itself is unaffected
      (it emits raw ANSI, no terminfo lookup).
- [ ] **Amp in vterm — choppy animations** — Amp's spinner/animations render
      jerkily in `vterm` compared to a native terminal (e.g. Ghostty). This is a
      vterm/Emacs redisplay limitation, not an Amp setting: `amp --help` shows
      the only animation control is `amp.terminal.animation` (default `true`,
      equivalently `NO_ANIMATION=1`), which just turns animation off rather than
      smoothing it. `vterm-timer-delay` (lowered to `0.01`/`nil`) is the main
      Emacs-side lever and didn't fully fix it; the `libgterm`/`emacs-libgterm`
      route was investigated and abandoned (needs Zig + a Ghostty build, glyph
      issues, prototype-level). Practical stance: use vterm for convenience and
      Ghostty for a polished TUI. Option if the half-rendered spinners are
      distracting: set `NO_ANIMATION=1` in the Emacs/vterm environment for a
      clean static display (trades animation for stability).

## Housekeeping

- [ ] Ensure every elisp file has the `lexical-binding: t` header.
- [ ] Keep docstrings checkdoc-clean (first line a sentence, no indented
      continuation lines, `` `symbol' `` quoting).
- [ ] Grow the `nix-paths.el` bridge as more store paths are needed (R, language
      servers, formatters).

## Possible ports from the old config (lower priority)

- [ ] `pdf-tools` for PDF viewing.
- [ ] `elm-mode` (Elm is used elsewhere in the dotfiles).
- [ ] `term` with `s-v` → `term-paste`.
- [ ] Snippets (e.g. `yasnippet`).
