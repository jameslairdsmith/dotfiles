;;; jls-interface.el --- General interactive interface -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup dashboard and minibuffer completion for full editor sessions.

;;; Code:

(declare-function jls/remove-buffer-from-window-history
                  "jls-window-management" (window buffer))

(use-package
 dashboard
 :ensure nil
 :demand t
 :custom
 (dashboard-items '((recents . 10) (projects . 5) (bookmarks . 5)))
 (dashboard-center-content t)
 :hook (dashboard-mode . evil-local-mode)
 :config (dashboard-setup-startup-hook))

(use-package
 mini-echo
 :ensure nil
 :custom
 (mini-echo-persistent-rule
  '(:long
    ("evil"
     "major-mode"
     "shrink-path"
     "project"
     "vcs"
     "flymake"
     "buffer-position"
     "buffer-size")
    :short
    ("evil" "buffer-name" "flymake" "buffer-position")))
 (mini-echo-buffer-status-style 'both)
 (mini-echo-separator "  ")
 :custom-face
 (mini-echo-minibuffer-window ((t (:inherit default))))
 (mini-echo-major-mode ((t (:inherit mode-line-emphasis :weight bold))))
 :config
 (define-key minibuffer-inactive-mode-map [mouse-1] #'ignore)
 (mini-echo-mode 1))

(use-package
 evil-collection
 :ensure nil
 :after (evil dashboard)
 :config (evil-collection-init 'dashboard))

(use-package vertico :ensure nil :init (vertico-mode 1))

(use-package marginalia :ensure nil :init (marginalia-mode 1))

(use-package savehist :ensure nil :init (savehist-mode 1))

(use-package
 orderless
 :ensure nil
 :custom
 (completion-styles '(orderless basic))
 (completion-category-defaults nil)
 (completion-category-overrides
  '((file (styles orderless partial-completion)))))

(use-package
 vertico-posframe
 :ensure nil
 :after vertico
 :config (vertico-posframe-mode 1))

(use-package
 vertico-quick
 :ensure nil
 :commands vertico-quick-exit)

(use-package
 vertico-buffer
 :ensure nil
 :after vertico
 :commands vertico-buffer-mode)

(defun jls/vertico-buffer-tab-name (buffer &optional buffers)
  "Name Vertico's minibuffer BUFFER like its prompt in the tab line.

Use the standard tab name for ordinary buffers.  BUFFERS is the complete tab
list supplied by `tab-line-tab-name-function'."
  (if (minibufferp buffer)
      (replace-regexp-in-string ":? *\\'" "" (minibuffer-prompt))
    (tab-line-tab-name-buffer buffer buffers)))

(defun jls/vertico-buffer-reset-tab-line ()
  "Remove the temporary tab line configuration from the minibuffer."
  (remove-hook
   'minibuffer-exit-hook #'jls/vertico-buffer-reset-tab-line t)
  (let ((buffer (current-buffer)))
    (dolist (window (window-list))
      (jls/remove-buffer-from-window-history window buffer)))
  (tab-line-mode -1)
  (kill-local-variable 'tab-line-tab-name-function))

(defun jls/vertico-buffer-setup-interface ()
  "Make an active Vertico Buffer look like an ordinary tabbed buffer."
  (when (bound-and-true-p vertico-buffer-mode)
    (face-remap-remove-relative
     '(default . mini-echo-minibuffer-window))
    (setq-local tab-line-tab-name-function #'jls/vertico-buffer-tab-name)
    (tab-line-mode 1)
    (add-hook
     'minibuffer-exit-hook #'jls/vertico-buffer-reset-tab-line 90 t)))

;; Run after Mini Echo adds its minibuffer face remapping.  Vertico Buffer
;; restores its own saved state, while the local exit hook removes the tab line.
(add-hook
 'minibuffer-setup-hook
 #'jls/vertico-buffer-setup-interface
 90)

(use-package
 vertico-multiform
 :ensure nil
 :after (vertico vertico-posframe)
 :custom
 (vertico-multiform-commands
  '((consult-buffer
     (:not posframe)
     (:keymap "C-q" vertico-quick-exit))
    (consult-line buffer (:not posframe))
    (jls/consult-grep-project buffer (:not posframe))))
 :config (vertico-multiform-mode 1))

(defvar jls-fd-program
  (if (boundp 'jls-cdmacs-fd-program)
      jls-cdmacs-fd-program
    "fd")
  "Path to the fd executable used by Consult commands.")

(use-package
 consult
 :ensure nil
 :commands (consult-buffer consult-fd consult-line)
 :custom
 (consult-async-min-input 1)
 (consult-fd-args
  (list jls-fd-program "--full-path --color=never")))

(use-package
 consult-dir
 :ensure nil
 :bind
 (("C-x C-d" . consult-dir)
  :map vertico-map
  ("C-x C-d" . consult-dir)
  ("C-x C-j" . consult-dir-jump-file)))

(provide 'jls-interface)
;;; jls-interface.el ends here
