;;; jls-grease.el --- Writable directory editing with Grease -*- lexical-binding: t; -*-

;;; Commentary:
;; Oil.nvim-style directory editing for full editor sessions.

;;; Code:

(declare-function grease--get-line-data "grease" ())
(declare-function grease-open "grease" (&optional directory target-file))
(declare-function grease-quit "grease" ())
(declare-function grease-up-directory "grease" ())
(declare-function grease-visit "grease" ())
(declare-function jls/current-project-root "jls-projects" ())

(defvar grease--buffer-dirty-p)
(defvar grease--pending-changes)
(defvar grease-mode-map)

(defun jls/open-grease ()
  "Open Grease, using the current project root when available."
  (interactive)
  (call-interactively #'grease-open))

(defun jls/grease-enter-or-up-directory ()
  "Enter the directory at point, or go to the parent directory.

This matches the custom `z' behaviour in the Oil configuration."
  (interactive)
  (if (eq (plist-get (grease--get-line-data) :type) 'dir)
      (grease-visit)
    (grease-up-directory)))

(defun jls/grease-quit-without-saving ()
  "Kill the current clean Grease buffer without committing changes.

Refuse to quit when the buffer contains staged changes, matching an unforced
Vim `:quit'.  Use `grease-save' first to commit them, or `grease-refresh' to
discard them."
  (interactive)
  (if (or grease--buffer-dirty-p grease--pending-changes)
      (user-error
       "Grease has staged changes; use :w to commit or g r to discard them")
    (kill-buffer (current-buffer))))

(defun jls/grease-save-and-close (function &rest arguments)
  "Save and close Grease, or call Evil FUNCTION with ARGUMENTS.

Grease buffers do not visit a file, so Evil's normal `:wq' implementation
cannot save them.  Delegate to `grease-quit', which commits the staged
filesystem changes and kills the buffer only when the save succeeds."
  (if (derived-mode-p 'grease-mode)
      (grease-quit)
    (apply function arguments)))

(defun jls/grease-open-in-project (function &optional directory target-file)
  "Call Grease FUNCTION for DIRECTORY and optional TARGET-FILE.

When invoked interactively in a project workspace, use that workspace's project
root without prompting.  Otherwise prompt for a directory as usual."
  (interactive
   (list
    (or (and (fboundp #'jls/current-project-root)
             (jls/current-project-root))
        (read-directory-name
         "Grease directory: " nil default-directory t))))
  (funcall function directory target-file))

(use-package
 grease
 :ensure nil
 :after evil
 :commands (grease-open grease-toggle grease-here)
 :init (advice-add #'grease-open :around #'jls/grease-open-in-project)
 :hook (grease-mode . evil-local-mode)
 :config
 (advice-add
  #'evil-save-and-close :around #'jls/grease-save-and-close)
 (evil-define-key
  'normal grease-mode-map
  "q" #'jls/grease-quit-without-saving
  "z" #'jls/grease-enter-or-up-directory))

(provide 'jls-grease)
;;; jls-grease.el ends here
