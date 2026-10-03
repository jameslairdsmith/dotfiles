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

(defun jls/hide-terminal-menu-bar (frame)
  "Hide the menu bar in terminal FRAME, leaving graphical frames unchanged."
  (unless (display-graphic-p frame)
    (set-frame-parameter frame 'menu-bar-lines 0)))

(jls/hide-terminal-menu-bar (selected-frame))
(add-hook 'after-make-frame-functions #'jls/hide-terminal-menu-bar)

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

(defun jls/copy-region (begin end)
  "Copy the region from BEGIN to END, including to the macOS clipboard."
  (interactive "r")
  (kill-ring-save begin end)
  (unless (display-graphic-p)
    (call-process-region begin end "/usr/bin/pbcopy")))

(global-set-key (kbd "s-c") #'jls/copy-region)
(global-set-key (kbd "s-v") #'yank) ; paste
(global-set-key (kbd "s-x") #'kill-region) ; cut
(global-set-key (kbd "s-p") #'execute-extended-command)
(global-set-key (kbd "s-<return>") #'eval-defun)

;;; Theme: built-in Modus themes (Protesilaos).
;; The library (toggle + options) ships in Emacs' own etc/themes dir,
;; which is on `custom-theme-load-path' but not `load-path'.  Add it so
;; `require' can find modus-themes.el.
(defun jls/macos-dark-mode-p ()
  "Return non-nil when macOS is using its dark appearance.
Use the Mac port's application state in the GUI.  In a terminal that state is
unavailable, so ask macOS directly instead."
  (let* ((application-state
          (and (fboundp 'mac-application-state) (mac-application-state)))
         (appearance (plist-get application-state :appearance)))
    (if appearance
        (string-match-p "Dark" appearance)
      (eq 0
          (call-process
           "/usr/bin/defaults"
           nil nil nil
           "read" "-g" "AppleInterfaceStyle")))))

(defun jls/sync-theme-with-macos ()
  "Use the Modus theme matching the current macOS appearance."
  (let ((theme (if (jls/macos-dark-mode-p)
                   'modus-vivendi
                 'modus-operandi)))
    (unless (and (memq theme custom-enabled-themes)
                 (= (length custom-enabled-themes) 1))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))))

(use-package
 modus-themes
 :ensure nil
 :init (add-to-list 'load-path (expand-file-name "themes" data-directory))
 (setq
  modus-themes-italic-constructs t
  modus-themes-bold-keywords t)
 :config
 (jls/sync-theme-with-macos)
 ;; GUI Emacs receives an immediate notification from the Mac port.  Polling
 ;; also covers terminal Emacs, where `mac-application-state' returns nil.
 (add-hook
  'mac-effective-appearance-change-hook #'jls/sync-theme-with-macos)
 (run-with-timer 2 2 #'jls/sync-theme-with-macos))

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

;;; Transient menus
(use-package
 transient
 :ensure nil
 :defer t
 :config
 (keymap-set transient-base-map "<escape>" #'transient-quit-one))

;;; Evil (Magit and Git commit buffers only)
(defun jls/git-commit-setup-evil ()
  "Enable Evil with `with-editor' commands in a Git commit buffer."
  (evil-local-mode 1)
  (evil-local-set-key 'normal (kbd "Z Z") #'with-editor-finish)
  (evil-local-set-key 'normal (kbd "Z Q") #'with-editor-cancel))

(use-package
 evil
 :ensure nil
 :init (setq evil-want-keybinding nil)
 :hook
 ((magit-mode . evil-local-mode)
  (git-commit-setup . jls/git-commit-setup-evil)))

(use-package
 evil-collection
 :ensure nil
 :after (evil magit)
 :config
 (evil-collection-init 'magit)
 (evil-collection-define-key
  'normal
  'magit-mode-map
  "z" #'magit-section-toggle)
 (evil-collection-define-key
  'normal
  'magit-status-mode-map
  "q" #'jls/magit-quit))

;;; Magit
(defvar jls/quick-magit-session nil
  "Whether this Emacs process is dedicated to a quick Magit session.")

(defvar jls/quick-magit-directory nil
  "Repository directory of the current quick Magit session.")

(defun jls/git-commit-use-quick-magit-directory ()
  "Restore the repository directory before setting up a commit buffer."
  (when (and jls/quick-magit-session jls/quick-magit-directory)
    (setq default-directory jls/quick-magit-directory)))

(with-eval-after-load 'git-commit
  (advice-add
   #'git-commit-setup
   :before #'jls/git-commit-use-quick-magit-directory))

(defun jls/magit-quit ()
  "Quit Magit, closing Emacs during a quick Magit session."
  (interactive)
  (if jls/quick-magit-session
      (save-buffers-kill-terminal)
    (magit-mode-bury-buffer)))

(use-package
 magit
 :ensure nil
 :commands magit-status
 :bind ("s-m" . magit-status)
 :custom
 (magit-display-buffer-function
  #'magit-display-buffer-same-window-except-diff-v1))

;;; LLM-assisted Magit actions
(defun jls/gptel-gemini-api-key ()
  "Read the Gemini API key from its private configuration file."
  (let ((key
         (with-temp-buffer
           (insert-file-contents "~/.config/google-gemini/api-key")
           (string-trim (buffer-string)))))
    (if (string-empty-p key)
        (user-error "The Gemini API key file is empty")
      key)))

(use-package
 gptel
 :ensure nil
 :defer t
 :config
 (require 'gptel-gemini)
 (setq
  gptel-include-reasoning nil
  gptel-model 'gemini-2.5-flash
  gptel-backend
  (gptel-make-gemini
   "Gemini"
   :stream t
   :key #'jls/gptel-gemini-api-key)))

(defun jls/gptel-magit-generate-message (buffer)
  "Generate a commit message and insert it into BUFFER."
  (require 'gptel-magit)
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (gptel-magit--generate
       (lambda (message)
         (when (buffer-live-p buffer)
           (with-current-buffer buffer
             (save-excursion
               (goto-char (point-min))
               (insert message)))))))
    (message "gptel-magit: Generating commit message...")))

(defun jls/gptel-magit-generate-message-if-empty ()
  "Generate a commit message when the commit buffer has no message."
  (unless (git-commit-buffer-message)
    (run-at-time
     0
     nil
     #'jls/gptel-magit-generate-message
     (current-buffer))))

(use-package
 gptel-magit
 :ensure nil
 :after magit
 :hook
 (git-commit-setup . jls/gptel-magit-generate-message-if-empty)
 :config (gptel-magit-install))

;;; vterm
(use-package
 vterm
 :ensure nil
 :commands vterm
 :config (setq vterm-timer-delay nil))

;;; Kitty keyboard protocol
(use-package kkp :ensure nil :config (global-kkp-mode 1))

(xterm-mouse-mode 1)

(use-package
 eat
 :ensure nil
 :commands (eat eat-project)
 :custom
 (eat-minimum-latency 0.008)
 (eat-minimum-latency 0.033))

(provide 'init)
;;; init.el ends here
