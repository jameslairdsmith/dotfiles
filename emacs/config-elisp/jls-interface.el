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

(use-package
 vertico-posframe
 :ensure nil
 :after vertico
 :config (vertico-posframe-mode 1))

;; Consult is installed by Nix as a dependency of Consult Dir, but its own
;; commands are not configured yet.

(use-package
 consult-dir
 :ensure nil
 :bind
 (("C-x C-d" . consult-dir)
  :map vertico-map
  ("C-x C-d" . consult-dir)
  ("C-x C-j" . consult-dir-jump-file)))

(provide 'jls-interface)
;;; jls-interface.el ends here
