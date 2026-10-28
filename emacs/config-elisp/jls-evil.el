;;; jls-evil.el --- Vim emulation for editing buffers -*- lexical-binding: t; -*-

;;; Commentary:
;; Enable Evil in programming and text buffers, including file-visiting
;; buffers for which Emacs has no specialised major mode.  Mode-specific
;; evil-collection integrations are configured by the modules which own those
;; modes.

;;; Code:

(defun jls/evil-enable-in-file-buffer ()
  "Enable Evil in a file buffer unless it uses a special major mode."
  (unless (derived-mode-p 'special-mode)
    (evil-local-mode 1)))

(use-package
 evil
 :ensure nil
 :init
 (setq evil-want-integration t
       evil-want-keybinding nil)
 :hook
 ((prog-mode text-mode) . evil-local-mode)
 (find-file . jls/evil-enable-in-file-buffer))

(provide 'jls-evil)
;;; jls-evil.el ends here
