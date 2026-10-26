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
  "Filesystem roots searched by the cdmacs filesystem source.")

(defconst
  jls/cdmacs-excluded-directories
  '(".git"
    "node_modules"
    ".direnv"
    ".devenv"
    ".cache"
    ".Trash"
    "Library"
    "**/jellyfin/Config"
    "result"
    "dist"
    "build"
    ".next"
    "target")
  "Directory names excluded from the cdmacs filesystem search.")

(defun jls/cdmacs-split-local-filter (_input _plist)
  "Send no input to fd and apply all input as a local Consult filter."
  '("" 0))

(add-to-list
 'consult-async-split-styles-alist
 `(cdmacs :function ,#'jls/cdmacs-split-local-filter))

(defun jls/cdmacs-fd-command (_input)
  "Return the fd command used to stream directory candidates."
  (let ((arguments
         (list
          jls-cdmacs-fd-program
          "--type"
          "directory"
          "--hidden"
          "--absolute-path")))
    (dolist (excluded jls/cdmacs-excluded-directories)
      (setq arguments (append arguments (list "--exclude" excluded))))
    (dolist
        (root
         (seq-filter
          #'file-directory-p
          (mapcar #'expand-file-name jls/cdmacs-search-roots)))
      (setq arguments
            (append arguments (list "--search-path" (file-truename root)))))
    arguments))

(defvar jls/cdmacs-source-filesystem
  `(:name "Filesystem"
    :narrow ?f
    :category file
    :face consult-file
    :history file-name-history
    :async ,(consult--process-collection
              #'jls/cdmacs-fd-command
              :min-input 0
              :debounce 0))
  "Asynchronous filesystem source matching the roots used by cdf.")

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

(defun jls/cdmacs-handle-terminal-deletion (_terminal)
  "Abort the active picker after its client terminal disappears."
  (when (active-minibuffer-window)
    ;; Let terminal deletion finish before unwinding the recursive minibuffer.
    (run-at-time 0 nil #'abort-recursive-edit)))

(add-hook
 'delete-terminal-functions
 #'jls/cdmacs-handle-terminal-deletion)

(defun jls/cdmacs-start (output-file)
  "Choose a directory and write it to OUTPUT-FILE, then close this client."
  (jls/cdmacs-remember-projects)
  (delete-other-windows)
  (let* ((selected-directory nil)
         (consult-async-split-style 'cdmacs)
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
