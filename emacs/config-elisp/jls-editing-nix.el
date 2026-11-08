;;; jls-editing-nix.el --- Nix editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Provide a Tree-sitter-backed major mode for Nix expressions.

;;; Code:

(defvar jls-nixd-program "nixd"
  "Path to the nixd language server executable.")

(defvar jls-nixfmt-program "nixfmt"
  "Path to the nixfmt executable.")

(use-package
 nix-ts-mode
 :ensure nil
 :mode ("\\.nix\\'" . nix-ts-mode))

(use-package
 eglot
 :ensure nil
 :commands (eglot eglot-ensure)
 :hook (nix-ts-mode . eglot-ensure)
 :config
 (add-to-list
  'eglot-server-programs `(nix-ts-mode . (,jls-nixd-program))))

(provide 'jls-editing-nix)
;;; jls-editing-nix.el ends here
