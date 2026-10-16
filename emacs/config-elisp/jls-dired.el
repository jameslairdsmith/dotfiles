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
 dired
 :ensure nil
 :commands dired
 :bind (:map dired-mode-map ("q" . jls/dired-quit)))

(provide 'jls-dired)
;;; jls-dired.el ends here
