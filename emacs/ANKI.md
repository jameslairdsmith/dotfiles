# Emacs config — Anki cards

Question/answer pairs distilled from the Emacs config rebuild thread. Format:
one card per `**Q:** / **A:**` pair, grouped by topic. Kept atomic for spaced
repetition.

## Emacs Mac port via Nix

**Q:** What is the nixpkgs attribute for the Yamamoto Mitsuharu Emacs Mac port?
**A:** `pkgs.emacs-macport` (the camel-case `emacsMacport` is a `throw` alias
and errors).

**Q:** From Emacs 30, whose source does nixpkgs build `emacs-macport` from, and
why? **A:** The `jdtsmith/emacs-mac` fork — Mitsuharu Yamamoto's upstream is
dormant.

**Q:** In Home Manager, how do you select the Mac port while keeping
`extraPackages` working? **A:** Set
`programs.emacs.package = pkgs.emacs-macport;`. `extraPackages` still works
because Home Manager builds the package set via `emacsPackagesFor cfg.package`.

**Q:** In the Mac port, what does the Command key map to once
`mac-command-modifier` is set to `super`? **A:** Command becomes the `super`
(`s-`) modifier (Option → `meta` via `mac-option-modifier`).

## use-package and the package system

**Q:** Since which Emacs version is `use-package` built in? **A:** 29.1.

**Q:** On Emacs 30, do you need `(require 'use-package)` before using the macro?
**A:** No — the `use-package` macro is autoloaded (`fboundp` is `t` before any
require); first use auto-loads it.

**Q:** Should a built-in package like `use-package` go in `extraPackages`?
**A:** No — that pulls a redundant ELPA copy that shadows the bundled core
version.

**Q:** What is the default value of `use-package-always-ensure`? **A:** `nil`
(so with Nix-managed packages you never need `:ensure nil` strictly, though it
documents intent).

**Q:** What does `(provide 'foo)` do? **A:** Adds `foo` to the global `features`
list so a later `(require 'foo)` becomes a no-op (avoids re-loading).

**Q:** Is `(provide 'init)` meaningful in `init.el`? **A:** No — `init.el` is
loaded by path, never via `(require 'init)`, so it's a no-op convention.

## use-package loading semantics

**Q:** Which `use-package` keywords cause a package to load lazily (deferred)?
**A:** `:bind`, `:commands`, `:hook`, `:mode`, `:interpreter` (they create
autoloads). Without one of these it loads eagerly.

**Q:** When do `:init` and `:config` run relative to the package's `require`?
**A:** `:init` runs before the require/load; `:config` runs after.

## early-init.el

**Q:** When is `early-init.el` loaded? **A:** Before the first GUI frame is
created and before `package.el` initialises.

**Q:** What belongs in `early-init.el`? **A:** UI-chrome disabling (so it never
flashes) and startup/GC tuning.

## Modus themes

**Q:** Why does `(require 'modus-themes)` fail by default even though the themes
load? **A:** The files live in Emacs' `etc/themes`, which is on
`custom-theme-load-path` but not `load-path`. `load-theme` works; `require`
doesn't.

**Q:** How do you put the bundled `modus-themes.el` on the load path without an
extra package? **A:**
`(add-to-list 'load-path (expand-file-name "themes" data-directory))`.

## mkOutOfStoreSymlink

**Q:** What's the difference between a plain `home.file` `.source = "${path}"`
and `mkOutOfStoreSymlink`? **A:** Plain interpolation of a Nix path copies a
frozen snapshot into the store (edits need a rebuild); `mkOutOfStoreSymlink`
points to the live file (edit and just restart).

**Q:** Why can't a Nix path literal be used with `mkOutOfStoreSymlink`? **A:**
Interpolating a path coerces it into the store; you need a string filesystem
path so the symlink stays live.

**Q:** Are `let` bindings shared between separate Nix module files? **A:** No —
each file has its own scope, so a module must re-declare e.g. `dotsDir`.

## elisp-autofmt

**Q:** Which `elisp-autofmt` function is meant for batch use? **A:**
`elisp-autofmt-buffer-to-file` (formats and writes the file directly);
`elisp-autofmt-buffer` only reformats the buffer.

**Q:** How do you keep `elisp-autofmt`'s Python out of your global shell PATH?
**A:** Generate a Nix file (`home.file ... .text`) that sets
`elisp-autofmt-python-bin` to the exact store path, and `load` it from
`init.el`.

## Formatting Emacs Lisp

**Q:** What two commands re-indent the whole buffer with no setup? **A:**
`C-x h` (`mark-whole-buffer`) then `C-M-\` (`indent-region`).

**Q:** Does `indent-region` reflow code? **A:** No — it only fixes indentation,
not line breaks/spacing.

**Q:** Which pure-elisp package reflows Lisp without needing Python (but is
stale)? **A:** `srefactor` (`srefactor-lisp-format-buffer` etc.) — uses the
built-in Semantic lexer; lightly maintained since ~2016.

## save-buffer behaviour

**Q:** Why doesn't `save-buffer` reformat an unmodified buffer? **A:**
`save-buffer` is a no-op when there are no changes, so `before-save-hook` (where
the formatter runs) never fires.

**Q:** How do you force `save-buffer` to run its hooks on an unmodified buffer?
**A:** `(set-buffer-modified-p t)` before `(save-buffer)` — but this always
bumps the mtime.

**Q:** Does `elisp-autofmt-buffer` change the file's mtime? **A:** No — it edits
only the in-memory buffer; the file is written (and mtime bumped) only if a
subsequent `save-buffer` finds the buffer modified.

## recentf and dashboard

**Q:** Which built-in mode tracks and persists recently opened files? **A:**
`recentf-mode`.

**Q:** What can `initial-buffer-choice` be, besides a file name? **A:** A
function that returns a buffer; that buffer becomes the startup buffer.

**Q:** What is the default `dashboard-projects-backend`? **A:** `'project-el`
(built-in `project.el`) — no projectile required.

**Q:** Are dashboard icons on by default? **A:** No —
`dashboard-set-heading-icons`/`-file-icons` default to `nil` (icons need
`nerd-icons`/`all-the-icons`).

## project.el

**Q:** Why does `project-switch-project` show "… (choose a dir)" instead of
filesystem completion? **A:** It completes over the list of _known_ projects,
not the filesystem; the entry is an escape hatch to add a new one.

**Q:** How do you bulk-register all projects under a directory? **A:**
`project-remember-projects-under "~/projects"` (add a `t` second arg to
recurse).

**Q:** Does opening a file with plain `find-file` register its project? **A:**
No — only project.el commands call `project-remember-project`. You can add a
`find-file-hook` to do it automatically.

**Q:** How do you find the current buffer's project root interactively? **A:**
`M-:` then `(project-root (project-current))`.

## Completion (vertico / consult)

**Q:** Is `consult` a completion UI? **A:** No — it's a set of enhanced commands
that run through `completing-read`; the vertical UI comes from `vertico` /
`fido-vertical-mode`.

**Q:** Does `consult` work with the default Emacs completion UI? **A:** Yes, its
commands run, but you lose the live type-to-filter list and most preview
benefits.

## Keybindings

**Q:** Why do `s-` (super) keybindings not work in terminal Emacs? **A:**
`mac-command-modifier` only applies to the GUI; terminals have no byte encoding
for super and macOS intercepts Command.

## Kitty Keyboard Protocol (kkp)

**Q:** What does `kkp.el` do? **A:** It enables the Kitty Keyboard Protocol in
terminal Emacs so terminals that speak it (e.g. Ghostty) can send disambiguated
keys, including the super and hyper modifiers, letting `s-` bindings reach
`emacs -nw`.

**Q:** Does `kkp` affect GUI (Mac port) frames? **A:** No — it is a terminal
protocol and no-ops in graphical frames, so GUI Emacs keeps its native
`mac-command-modifier` handling.

**Q:** What is the `tty-setup` hook (`tty-setup-hook`)? **A:** A hook Emacs runs
once each time a new text-terminal (TTY) frame is initialised — e.g. on
`emacs -nw` or `emacsclient -nw` — after the terminal's capabilities and
`input-decode-map` are set up. It never runs for GUI frames.

**Q:** Why hook `global-kkp-mode` onto `tty-setup` instead of just calling
`(global-kkp-mode 1)` at startup? **A:** `tty-setup` only fires for terminal
frames (so it's skipped on the GUI Mac port) and runs per-terminal, including
terminals created later in the same session.

**Q:** How do you check whether KKP is active in the current terminal? **A:**
`M-x kkp-status`.

## Mouse in terminal Emacs

**Q:** How do you get mouse support in terminal Emacs? **A:** Enable the
built-in `xterm-mouse-mode` (e.g. `(xterm-mouse-mode 1)`); it decodes the
terminal's mouse escape sequences into Emacs mouse events (click,
drag-to-select, wheel scroll). No extra package is needed.

**Q:** Does `xterm-mouse-mode` need a package or affect GUI frames? **A:** No —
it is built in and only does anything in TTY frames, so it is harmless for the
GUI Mac port.

**Q:** What is the trade-off of enabling `xterm-mouse-mode`? **A:** Emacs
captures mouse events, so the terminal's own click-drag selection (for the OS
clipboard) no longer works inside Emacs; hold a modifier (Shift+drag in Ghostty)
to fall back to the terminal's native selection.

## Quitting Emacs

**Q:** What does `save-buffers-kill-terminal` (`C-x C-c`) do? **A:** It offers
to save buffers then kills the current connection/frame: in an `emacsclient`
frame it closes just that client (the daemon keeps running); in a standalone
Emacs with no client it falls through to `save-buffers-kill-emacs` and quits
Emacs.

**Q:** What does `save-buffers-kill-emacs` do? **A:** It offers to save buffers
then kills the entire Emacs process — all frames, all clients, the daemon —
running the full shutdown ceremony (`process-query-on-exit-flag`,
`kill-emacs-query-functions`, `confirm-kill-emacs`) and can optionally restart.

**Q:** Why is `C-x C-c` bound to `save-buffers-kill-terminal` rather than
`save-buffers-kill-emacs`? **A:** It is the client-aware "I'm done with this
window" command: it does the right thing whether or not you use the daemon,
closing just one client connection instead of always bringing down everything.
