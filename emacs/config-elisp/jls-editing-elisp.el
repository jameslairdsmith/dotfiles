;;; jls-editing-elisp.el --- Emacs Lisp editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Formatting and saving support for Emacs Lisp buffers.

;;; Code:

(require 'jls-core)

(defun jls/save-buffer-el ()
  "Reformat the current Emacs Lisp buffer, then save it."
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

(provide 'jls-editing-elisp)
;;; jls-editing-elisp.el ends here
