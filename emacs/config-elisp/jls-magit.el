;;; jls-magit.el --- Magit task configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Magit, its local Evil bindings, and commit-message generation.  This module
;; is sufficient for both full editor sessions and the dedicated Magit profile.

;;; Code:

(require 'subr-x)

(use-package
 transient
 :ensure nil
 :defer t
 :config
 (keymap-set transient-base-map "<escape>" #'transient-quit-one))

(defun jls/git-commit-setup-evil ()
  "Enable Evil with `with-editor' commands in a Git commit buffer."
  (evil-local-mode 1)
  (evil-local-set-key 'normal (kbd "Z Z") #'with-editor-finish)
  (evil-local-set-key 'normal (kbd "Z Q") #'with-editor-cancel))

(use-package
 evil-collection
 :ensure nil
 :after (evil magit)
 :hook
 ((magit-mode . evil-local-mode)
  (git-commit-setup . jls/git-commit-setup-evil))
 :config
 (evil-collection-init 'magit)
 (evil-collection-define-key
  'normal
  'magit-mode-map
  "z" #'magit-section-toggle)
 (evil-collection-define-key
  'normal
  'magit-status-mode-map
  "q" #'jls/magit-quit))

(defvar jls/quick-magit-session nil
  "Whether this Emacs process is dedicated to a quick Magit session.")

(defvar jls/quick-magit-directory nil
  "Repository directory of the current quick Magit session.")

(defun jls/git-commit-use-quick-magit-directory ()
  "Restore the repository directory before setting up a commit buffer."
  (when (and jls/quick-magit-session jls/quick-magit-directory)
    (setq default-directory jls/quick-magit-directory)))

(with-eval-after-load 'git-commit
  (advice-add
   #'git-commit-setup
   :before #'jls/git-commit-use-quick-magit-directory))

(defun jls/magit-quit ()
  "Quit Magit, closing Emacs during a quick Magit session."
  (interactive)
  (if jls/quick-magit-session
      (save-buffers-kill-terminal)
    (magit-mode-bury-buffer)))

(use-package
 magit
 :ensure nil
 :commands magit-status
 :bind ("s-m" . magit-status)
 :custom
 (magit-display-buffer-function
  #'magit-display-buffer-same-window-except-diff-v1))

(defun jls/gptel-gemini-api-key ()
  "Read the Gemini API key from its private configuration file."
  (let ((key
         (with-temp-buffer
           (insert-file-contents "~/.config/google-gemini/api-key")
           (string-trim (buffer-string)))))
    (if (string-empty-p key)
        (user-error "The Gemini API key file is empty")
      key)))

(use-package
 gptel
 :ensure nil
 :defer t
 :config
 (require 'gptel-gemini)
 (setq
  gptel-include-reasoning nil
  gptel-model 'gemini-2.5-flash
  gptel-backend
  (gptel-make-gemini
   "Gemini"
   :stream t
   :key #'jls/gptel-gemini-api-key)))

(defun jls/gptel-magit-generate-message (buffer)
  "Generate a commit message and insert it into BUFFER."
  (require 'gptel-magit)
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (gptel-magit--generate
       (lambda (message)
         (when (buffer-live-p buffer)
           (with-current-buffer buffer
             (save-excursion
               (goto-char (point-min))
               (insert message)))))))
    (message "gptel-magit: Generating commit message...")))

(defun jls/gptel-magit-generate-message-if-empty ()
  "Generate a commit message when the commit buffer has no message."
  (unless (git-commit-buffer-message)
    (run-at-time
     0
     nil
     #'jls/gptel-magit-generate-message
     (current-buffer))))

(use-package
 gptel-magit
 :ensure nil
 :after magit
 :hook
 (git-commit-setup . jls/gptel-magit-generate-message-if-empty)
 :config (gptel-magit-install))

(provide 'jls-magit)
;;; jls-magit.el ends here
