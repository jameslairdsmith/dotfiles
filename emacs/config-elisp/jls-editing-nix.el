;;; jls-editing-nix.el --- Nix editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Provide a Tree-sitter-backed major mode for Nix expressions.

;;; Code:

(use-package
 nix-ts-mode
 :ensure nil
 :mode ("\\.nix\\'" . nix-ts-mode))

(provide 'jls-editing-nix)
;;; jls-editing-nix.el ends here
