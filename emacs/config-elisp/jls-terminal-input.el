;;; jls-terminal-input.el --- Terminal input support -*- lexical-binding: t; -*-

;;; Commentary:
;; Mouse support and the Kitty keyboard protocol for terminal sessions.

;;; Code:

(use-package kkp :ensure nil :config (global-kkp-mode 1))

(xterm-mouse-mode 1)

(provide 'jls-terminal-input)
;;; jls-terminal-input.el ends here
