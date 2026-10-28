;;; jls-editing-r.el --- R editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Provide R major-mode support through ESS.  Evil is enabled automatically
;; because `ess-r-mode' derives from `prog-mode'.

;;; Code:

(use-package
 ess-r-mode
 :ensure nil
 :mode ("\\.R\\'" . R-mode))

(provide 'jls-editing-r)
;;; jls-editing-r.el ends here
