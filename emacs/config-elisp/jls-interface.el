;;; jls-interface.el --- General interactive interface -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup dashboard and minibuffer completion for full editor sessions.

;;; Code:

(use-package
 dashboard
 :ensure nil
 :custom
 (dashboard-items '((recents . 10) (projects . 5) (bookmarks . 5)))
 (dashboard-center-content t)
 :config (dashboard-setup-startup-hook))

(use-package vertico :ensure nil :init (vertico-mode 1))

;; Consult is installed by Nix but not configured yet.

(provide 'jls-interface)
;;; jls-interface.el ends here
