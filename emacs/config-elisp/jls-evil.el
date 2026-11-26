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
 (setq
  evil-want-integration t
  evil-want-keybinding nil)
 :hook
 ((prog-mode text-mode) . evil-local-mode)
 (find-file . jls/evil-enable-in-file-buffer)
 :config
 ;; Evil can mistake the frame-selection event from a focus click for the
 ;; beginning of a drag and leave the buffer in Visual state.
 (define-key
  evil-motion-state-map [down-mouse-1] #'mouse-drag-region))

(use-package
 evil-collection
 :ensure nil
 :after evil
 :demand t
 :hook (messages-buffer-mode . evil-local-mode)
 :config (evil-collection-init 'simple)
 ;; `*Messages*' normally exists before its mode hook is configured.
 (when-let ((buffer (get-buffer "*Messages*")))
   (with-current-buffer buffer
     (evil-local-mode 1))))

(provide 'jls-evil)
;;; jls-evil.el ends here
