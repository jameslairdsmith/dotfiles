;;; jls-olivetti.el --- Centred editing layout -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep prose and programming text comfortably centred in wide windows.

;;; Code:

(defun jls/enable-olivetti-mode ()
  "Centre the editing area with Olivetti."
  (olivetti-mode 1))

(use-package
 olivetti
 :ensure nil
 :custom (olivetti-body-width 110)
 :hook ((prog-mode text-mode) . jls/enable-olivetti-mode))

(provide 'jls-olivetti)
;;; jls-olivetti.el ends here
