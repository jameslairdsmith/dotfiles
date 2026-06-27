;;; init.el --- JLS Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Fresh config.  Packages are installed by Nix (Home Manager
;; programs.emacs.extraPackages).

;;; Code:

;; Load Nix-injected store paths (sets elisp-autofmt-python-bin, etc.).
(load (locate-user-emacs-file "nix-paths") t)

;;; macOS modifier keys (Mac port): Command = super, Option = meta.
(setq mac-command-modifier 'super)
(setq mac-option-modifier 'meta)

;;; Sane defaults
(setq inhibit-startup-message t)
(setq visible-bell t) ; flash instead of beeping
(show-paren-mode 1)
(setq make-backup-files nil)

;;; Make ESC quit prompts without nuking your window layout.
(defun jls/keyboard-escape-quit-adv (fun)
  "Around advice for `keyboard-escape-quit' FUN: keep window config."
  (let ((buffer-quit-function (or buffer-quit-function #'ignore)))
    (funcall fun)))

(advice-add
 #'keyboard-escape-quit
 :around #'jls/keyboard-escape-quit-adv)

(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;;; Custom saving
(defvar jls/save-buffer-dispatch nil
  "Alist mapping a major mode to a function that saves its buffers.
Each mode's config registers an entry; `jls/save-buffer' dispatches on it.")

(defun jls/save-buffer ()
  "Save the current buffer using a mode-specific saver when available.
Looks up `major-mode' in `jls/save-buffer-dispatch'; falls back to
plain `save-buffer' if no specific saver is registered."
  (interactive)
  (let ((saver (alist-get major-mode jls/save-buffer-dispatch)))
    (if saver
        (funcall saver)
      (save-buffer))))

(global-set-key (kbd "s-s") #'jls/save-buffer)

;;; Other keybindings

(global-set-key (kbd "s-c") #'kill-ring-save) ; copy
(global-set-key (kbd "s-v") #'yank) ; paste
(global-set-key (kbd "s-x") #'kill-region) ; cut
(global-set-key (kbd "s-p") #'execute-extended-command)
(global-set-key (kbd "s-<return>") #'eval-defun)

;;; Theme: built-in Modus themes (Protesilaos).
;; The library (toggle + options) ships in Emacs' own etc/themes dir,
;; which is on `custom-theme-load-path' but not `load-path'.  Add it so
;; `require' can find modus-themes.el.
(use-package
 modus-themes
 :ensure nil
 :init (add-to-list 'load-path (expand-file-name "themes" data-directory))
 ;(require 'modus-themes)
 (setq
  modus-themes-italic-constructs t
  modus-themes-bold-keywords t)
 :config (load-theme 'modus-operandi t))

;;; Auto-formatting elisp
(defun jls/save-buffer-el ()
  "Reformat the buffer with `elisp-autofmt', then save.
Writes (and bumps mtime) only when the reformat actually changed
something, since `save-buffer' is a no-op on an unmodified buffer."
  (interactive)
  (when (bound-and-true-p elisp-autofmt-mode)
    (elisp-autofmt-buffer))
  (save-buffer))

(add-to-list
 'jls/save-buffer-dispatch '(emacs-lisp-mode . jls/save-buffer-el))

(use-package
 elisp-autofmt
 :ensure nil
 :commands (elisp-autofmt-mode elisp-autofmt-buffer)
 :custom (elisp-autofmt-on-save-p 'always)
 :hook (emacs-lisp-mode . elisp-autofmt-mode))

;;; Dashboard
(use-package
 dashboard
 :ensure nil
 :custom
 (dashboard-items '((recents . 10) (projects . 5) (bookmarks . 5)))
 (dashboard-center-content t)
 :config (dashboard-setup-startup-hook))

;;; Vertico
(use-package vertico :ensure nil :init (vertico-mode 1))

;;; Consult
;(use-package consult
;  :ensure nil
;  :)

;;; vterm
(use-package
 vterm
 :ensure nil
 :commands vterm
 :config (setq vterm-timer-delay nil))

(provide 'init)
;;; init.el ends here
