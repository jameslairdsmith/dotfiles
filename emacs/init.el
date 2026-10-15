;;; init.el --- JLS Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Bootstrap the modular configuration.  Packages are installed by Nix through
;; Home Manager's `programs.emacs.extraPackages'.

;;; Code:

;; Load Nix-injected store paths (sets elisp-autofmt-python-bin, etc.).
(load (locate-user-emacs-file "nix-paths") t)

;; Resolve this file's source so the modules are available immediately through
;; the out-of-store symlink, even before a new Home Manager generation is
;; activated.
(defconst jls/config-directory
  (file-name-directory (file-truename (or load-file-name user-init-file)))
  "Directory containing this Emacs configuration.")

(add-to-list
 'load-path (expand-file-name "config-elisp" jls/config-directory))

(require 'jls-profiles)
(jls/load-session-profile (or (getenv "JLS_EMACS_PROFILE") "full"))

(provide 'init)
;;; init.el ends here
