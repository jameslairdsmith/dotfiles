;;; jls-cdmacs.el --- Directory picker for shell sessions -*- lexical-binding: t; -*-

;;; Commentary:
;; A full-window Consult Dir picker which writes the selected directory to a
;; file for the invoking shell.

;;; Code:

(use-package vertico :ensure nil :init (vertico-mode 1))

(use-package
  vertico-buffer
  :ensure nil
  :after vertico
  :custom (vertico-buffer-display-action '(display-buffer-same-window))
  :config (vertico-buffer-mode 1))

(use-package
 consult-dir
 :ensure nil
 :demand t
 :config
 ;; The invoking local shell cannot `cd' into a TRAMP path.
 (setq consult-dir-sources
       (remove #'consult-dir--source-tramp-local consult-dir-sources)))

(defun jls/cdmacs-start (output-file)
  "Choose a directory and write it to OUTPUT-FILE, then close this client."
  (delete-other-windows)
  (let* ((selected-directory nil)
         (consult-dir-default-command
          (lambda ()
            (interactive)
            (setq selected-directory default-directory))))
    (condition-case nil
        (consult-dir)
      (quit nil))
    (when selected-directory
      (with-temp-file output-file
        (insert (file-truename selected-directory))))
    (save-buffers-kill-terminal)))

(provide 'jls-cdmacs)
;;; jls-cdmacs.el ends here
