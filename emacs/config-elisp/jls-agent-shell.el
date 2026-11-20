;;; jls-agent-shell.el --- Agent Shell task configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Agent Shell configuration shared by full editor sessions and the dedicated
;; terminal profile.

;;; Code:

(use-package
 agent-shell
 :ensure nil
 :demand t
 :hook
 ((agent-shell-mode . evil-local-mode)
  (agent-shell-diff-mode . evil-local-mode)
  (agent-shell-viewport-edit-mode . evil-local-mode)
  (agent-shell-viewport-view-mode . evil-local-mode))
 :config
 (require 'agent-shell-pi)
 (setq agent-shell-pi-acp-command '("pi-acp")))

(use-package
 evil-collection
 :ensure nil
 :after (evil agent-shell)
 :config (evil-collection-init 'agent-shell))

(provide 'jls-agent-shell)
;;; jls-agent-shell.el ends here
