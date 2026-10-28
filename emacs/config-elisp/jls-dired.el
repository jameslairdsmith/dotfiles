;;; jls-dired.el --- Dired task configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Dired configuration shared by full editor sessions and the dedicated Dired
;; session profile.

;;; Code:

(defun jls/dired-quit ()
  "Quit Dired, closing Emacs during a dedicated Dired session."
  (interactive)
  (if (eq jls/session-profile 'dired)
      (save-buffers-kill-terminal)
    (quit-window)))

(use-package
 evil-collection
 :ensure nil
 :after (evil dired)
 :hook (dired-mode . evil-local-mode)
 :config
 (evil-collection-init 'dired)
 (evil-collection-define-key
  'normal
  'dired-mode-map
  "q" #'jls/dired-quit))

(use-package
 dired
 :ensure nil
 :commands dired
 :hook (dired-mode . dired-hide-details-mode)
 :bind (:map dired-mode-map ("q" . jls/dired-quit)))

(provide 'jls-dired)
;;; jls-dired.el ends here
