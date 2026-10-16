;;; jls-profiles.el --- Purpose-specific session profiles -*- lexical-binding: t; -*-

;;; Commentary:
;; A session profile is a small set of configuration modules for one way of
;; starting Emacs.  JLS_EMACS_PROFILE selects a profile before init.el loads;
;; an ordinary editor session uses `full'.

;;; Code:

(defconst jls/session-profiles
  '((full
     jls-core
     jls-appearance
     jls-editing-elisp
     jls-interface
     jls-dired
     jls-magit
     jls-terminal-input
     jls-terminal-emulators)
    (magit
     jls-core
     jls-appearance
     jls-terminal-input
     jls-magit)
    (dired
     jls-core
     jls-appearance
     jls-terminal-input
     jls-dired))
  "Configuration modules loaded by each Emacs session profile.")

(defvar jls/session-profile nil
  "The session profile selected while loading the Emacs configuration.")

(defun jls/load-session-profile (profile-name)
  "Load the session profile named PROFILE-NAME.
PROFILE-NAME is a string, normally read from `JLS_EMACS_PROFILE'."
  (let* ((profile (intern profile-name))
         (entry (assq profile jls/session-profiles)))
    (unless entry
      (error
       "Unknown Emacs session profile %S (expected one of: %s)"
       profile-name
       (mapconcat (lambda (item) (symbol-name (car item)))
                  jls/session-profiles
                  ", ")))
    (setq jls/session-profile profile)
    (mapc #'require (cdr entry))))

(provide 'jls-profiles)
;;; jls-profiles.el ends here
