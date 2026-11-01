;;; jls-terminal-emulators.el --- Terminal emulators -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal emulators used from full editor sessions.

;;; Code:

(declare-function evil-collection-init "evil-collection" (&optional modes))

(defun jls/vterm-delete-windows-on-exit (buffer _event)
  "Delete deletable windows displaying the exited vterm BUFFER."
  (when (buffer-live-p buffer)
    (dolist (window (get-buffer-window-list buffer nil t))
      ;; Do not delete a frame when its sole window displays the vterm.
      (when (eq (window-deletable-p window) t)
        (delete-window window)))))

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
 eat
 :ensure nil
 :commands (eat eat-project)
 :custom
 (eat-minimum-latency 0.008)
 (eat-minimum-latency 0.033))

(provide 'jls-terminal-emulators)
;;; jls-terminal-emulators.el ends here
