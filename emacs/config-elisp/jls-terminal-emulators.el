;;; jls-terminal-emulators.el --- Terminal emulators -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal emulators used from full editor sessions.

;;; Code:

(declare-function evil-collection-init "evil-collection" (&optional modes))

(defun jls/delete-deletable-buffer-windows (buffer)
  "Delete every deletable window displaying BUFFER."
  (when (buffer-live-p buffer)
    (dolist (window (get-buffer-window-list buffer nil t))
      ;; Do not delete a frame when its sole window displays the buffer.
      (when (eq (window-deletable-p window) t)
        (delete-window window)))))

(defun jls/vterm-delete-windows-on-exit (buffer _event)
  "Delete deletable windows displaying the exited vterm BUFFER."
  (jls/delete-deletable-buffer-windows buffer))

(defun jls/eshell-delete-windows-on-exit ()
  "Delete deletable windows displaying the exiting Eshell buffer."
  (jls/delete-deletable-buffer-windows (current-buffer)))

(defun jls/evil-collection-eshell-bind-return ()
  "Make Return submit input from Evil's insert state in Eshell."
  (evil-define-key 'insert eshell-mode-map
    (kbd "RET") #'eshell-send-input
    (kbd "<return>") #'eshell-send-input
    (kbd "C-m") #'eshell-send-input))

(add-hook 'eshell-exit-hook #'jls/eshell-delete-windows-on-exit)

(use-package
 vterm
 :ensure nil
 :commands vterm
 :init
 (add-hook 'vterm-exit-functions #'jls/vterm-delete-windows-on-exit)
 ;; Keep vterm's refresh delay non-nil.  Nil refreshes after every output
 ;; update, which can overwhelm Emacs's redisplay when several vterms run.
 :custom (vterm-timer-delay 0.1))

(use-package
 evil-collection
 :ensure nil
 :after (evil vterm)
 :demand t
 :hook (vterm-mode . evil-local-mode)
 :config (evil-collection-init 'vterm))

(use-package
 evil-collection
 :ensure nil
 :after (evil eshell)
 :demand t
 :hook
 (eshell-mode . evil-local-mode)
 (eshell-mode . jls/evil-collection-eshell-bind-return)
 :config (evil-collection-init 'eshell))

(use-package
 eat
 :ensure nil
 :commands (eat eat-project eat-eshell-mode)
 :init
 (add-hook 'eshell-load-hook #'eat-eshell-mode)
 :custom
 ;; Prevent commands such as `top' from bypassing Eat via Eshell's old `term'
 ;; path; Eat provides terminal emulation directly in the Eshell buffer.
 (eshell-visual-commands nil)
 ;; macOS's system ncurses cannot read Eat's Nix-built `eat-truecolor'
 ;; terminfo entry.  Use a terminal type understood by both macOS and Nix.
 ;; This limits applications to the 256-colour palette instead of advertising
 ;; true-colour support; see the corresponding entry in emacs/TODO.md.
 (eat-term-name "xterm-256color")
 (eat-minimum-latency 0.008)
 (eat-maximum-latency 0.033))

(provide 'jls-terminal-emulators)
;;; jls-terminal-emulators.el ends here
