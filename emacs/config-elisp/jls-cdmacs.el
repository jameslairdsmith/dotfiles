;;; jls-cdmacs.el --- Directory picker for shell sessions -*- lexical-binding: t; -*-

;;; Commentary:
;; A full-window Consult Dir picker which writes the selected directory to a
;; file for the invoking shell.

;;; Code:

(require 'project)
(require 'seq)

(use-package vertico :ensure nil :init (vertico-mode 1))

(use-package
  orderless
  :ensure nil
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles orderless partial-completion)))))

(use-package
  vertico-buffer
  :ensure nil
  :after vertico
  :custom (vertico-buffer-display-action '(display-buffer-same-window))
  :config (vertico-buffer-mode 1))

(use-package consult-dir :ensure nil :demand t)

(defvar jls-cdmacs-fd-program "fd"
  "Path to the fd executable used to find directory candidates.")

(defconst jls/cdmacs-search-roots '("~" "/Applications" "/Volumes" "/opt")
  "Filesystem roots searched by `jls/cdmacs-filesystem-dirs'.")

(defconst
  jls/cdmacs-excluded-directories
  '(".git"
    "node_modules"
    ".direnv"
    ".devenv"
    ".cache"
    ".Trash"
    "Library"
    "result"
    "dist"
    "build"
    ".next"
    "target")
  "Directory names excluded from the cdmacs filesystem search.")

(defun jls/cdmacs-filesystem-dirs ()
  "Return directories under `jls/cdmacs-search-roots' using fd."
  (let* ((roots
          (mapcar
           #'file-truename
           (seq-filter
            #'file-directory-p
            (mapcar #'expand-file-name jls/cdmacs-search-roots))))
         ;; Consult Dir materialises every candidate, unlike fzf's streaming
         ;; walker, so avoid following symlinks into millions of duplicates.
         (arguments '("--type" "directory" "--hidden" "--absolute-path")))
    (dolist (excluded jls/cdmacs-excluded-directories)
      (setq arguments (append arguments (list "--exclude" excluded))))
    (dolist (root roots)
      (setq arguments (append arguments (list "--search-path" root))))
    (condition-case error-data
        (delete-dups
         (append
          roots
          (apply #'process-lines jls-cdmacs-fd-program arguments)))
      (error
       (message
        "cdmacs filesystem search failed: %s"
        (error-message-string error-data))
       roots))))

(defvar jls/cdmacs-source-filesystem
  `(:name "Filesystem"
	  :narrow ?f
	  :category file
	  :face consult-file
	  :history file-name-history
	  :items ,#'jls/cdmacs-filesystem-dirs)
  "Consult Dir source matching the roots and exclusions used by cdf.")

;; The invoking local shell cannot `cd' into a TRAMP path.
(setq consult-dir-sources
      (remove #'consult-dir--source-tramp-local consult-dir-sources))
(add-to-list 'consult-dir-sources #'jls/cdmacs-source-filesystem t)

(defconst jls/cdmacs-projects-directory "~/projects"
  "Directory whose immediate children cdmacs registers with project.el.")

(defun jls/cdmacs-remember-projects ()
  "Register projects immediately below `jls/cdmacs-projects-directory'."
  (let ((projects-directory
         (expand-file-name jls/cdmacs-projects-directory)))
    (when (file-directory-p projects-directory)
      (let ((inhibit-message t))
        (project-remember-projects-under projects-directory)))))

(defun jls/cdmacs-remember-selected-project (directory)
  "Remember the project containing DIRECTORY, when project.el recognises one."
  (when-let ((project (project-current nil directory)))
    (project-remember-project project)))

(defun jls/cdmacs-start (output-file)
  "Choose a directory and write it to OUTPUT-FILE, then close this client."
  (jls/cdmacs-remember-projects)
  (delete-other-windows)
  (let* ((selected-directory nil)
         (consult-dir-default-command
          (lambda ()
            (interactive)
            (setq selected-directory default-directory))))
    (condition-case nil
        (consult-dir)
      (quit nil))
    (when selected-directory
      (jls/cdmacs-remember-selected-project selected-directory)
      (with-temp-file output-file
        (insert (file-truename selected-directory))))
    (save-buffers-kill-terminal)))

(provide 'jls-cdmacs)
;;; jls-cdmacs.el ends here
