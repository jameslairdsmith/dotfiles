;;; jls-evil.el --- Vim emulation for editing buffers -*- lexical-binding: t; -*-

;;; Commentary:
;; Enable Evil in programming buffers.  Mode-specific evil-collection
;; integrations are configured by the modules which own those modes.

;;; Code:

(use-package
 evil
 :ensure nil
 :init
 (setq evil-want-integration t
       evil-want-keybinding nil)
 :hook (prog-mode . evil-local-mode))

(provide 'jls-evil)
;;; jls-evil.el ends here
