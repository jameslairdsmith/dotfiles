;;; jls-interface.el --- General interactive interface -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup dashboard and minibuffer completion for full editor sessions.

;;; Code:

(use-package
 dashboard
 :ensure nil
 :demand t
 :custom
 (dashboard-items '((recents . 10) (projects . 5) (bookmarks . 5)))
 (dashboard-center-content t)
 :hook (dashboard-mode . evil-local-mode)
 :config (dashboard-setup-startup-hook))

(use-package
 evil-collection
 :ensure nil
 :after (evil dashboard)
 :config (evil-collection-init 'dashboard))

(use-package vertico :ensure nil :init (vertico-mode 1))

(use-package
 vertico-posframe
 :ensure nil
 :after vertico
 :config (vertico-posframe-mode 1))

(defvar jls-fd-program
  (if (boundp 'jls-cdmacs-fd-program)
      jls-cdmacs-fd-program
    "fd")
  "Path to the fd executable used by Consult commands.")

(use-package
 consult
 :ensure nil
 :commands consult-fd
 :custom
 (consult-async-min-input 1)
 (consult-fd-args
  (list jls-fd-program "--full-path --color=never")))

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
