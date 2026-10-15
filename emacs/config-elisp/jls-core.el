;;; jls-core.el --- Shared Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Configuration shared by every interactive Emacs session profile.

;;; Code:

;; macOS modifier keys (Mac port): Command = super, Option = meta.
(setq mac-command-modifier 'super)
(setq mac-option-modifier 'meta)

(setq inhibit-startup-message t)
(setq visible-bell t)
(show-paren-mode 1)
(setq make-backup-files nil)

(defun jls/hide-terminal-menu-bar (frame)
  "Hide the menu bar in terminal FRAME, leaving graphical frames unchanged."
  (unless (display-graphic-p frame)
    (set-frame-parameter frame 'menu-bar-lines 0)))

(jls/hide-terminal-menu-bar (selected-frame))
(add-hook 'after-make-frame-functions #'jls/hide-terminal-menu-bar)

(defun jls/keyboard-escape-quit-adv (fun)
  "Around advice for `keyboard-escape-quit' FUN: keep window config."
  (let ((buffer-quit-function (or buffer-quit-function #'ignore)))
    (funcall fun)))

(advice-add
 #'keyboard-escape-quit
 :around #'jls/keyboard-escape-quit-adv)

(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

(defvar jls/save-buffer-dispatch nil
  "Alist mapping a major mode to a function that saves its buffers.
Each mode's config registers an entry; `jls/save-buffer' dispatches on it.")

(defun jls/save-buffer ()
  "Save the current buffer using a mode-specific saver when available.
Look up `major-mode' in `jls/save-buffer-dispatch'; fall back to plain
`save-buffer' if no specific saver is registered."
  (interactive)
  (let ((saver (alist-get major-mode jls/save-buffer-dispatch)))
    (if saver
        (funcall saver)
      (save-buffer))))

(global-set-key (kbd "s-s") #'jls/save-buffer)

(defun jls/copy-region (begin end)
  "Copy the region from BEGIN to END, including to the macOS clipboard."
  (interactive "r")
  (kill-ring-save begin end)
  (unless (display-graphic-p)
    (call-process-region begin end "/usr/bin/pbcopy")))

(global-set-key (kbd "s-c") #'jls/copy-region)
(global-set-key (kbd "s-v") #'yank)
(global-set-key (kbd "s-x") #'kill-region)
(global-set-key (kbd "s-p") #'execute-extended-command)
(global-set-key (kbd "s-<return>") #'eval-defun)

(provide 'jls-core)
;;; jls-core.el ends here
