;;; jls-agent-shell.el --- Agent Shell task configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Configuration for the dedicated terminal Agent Shell profile.

;;; Code:

(use-package
 agent-shell
 :ensure nil
 :config
 (require 'agent-shell-pi)
 (setq agent-shell-pi-acp-command '("pi-acp")))

(provide 'jls-agent-shell)
;;; jls-agent-shell.el ends here
