;;; jls-appearance.el --- Appearance configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep the configured light and dark themes in step with the macOS appearance.

;;; Code:

(defun jls/macos-dark-mode-p ()
  "Return non-nil when macOS is using its dark appearance.
Use the Mac port's application state in the GUI.  In a terminal that state is
unavailable, so ask macOS directly instead."
  (let* ((application-state
          (and (fboundp 'mac-application-state) (mac-application-state)))
         (appearance (plist-get application-state :appearance)))
    (if appearance
        (string-match-p "Dark" appearance)
      (eq 0
          (call-process
           "/usr/bin/defaults"
           nil nil nil
           "read" "-g" "AppleInterfaceStyle")))))

(defun jls/sync-theme-with-macos ()
  "Use the theme matching the current macOS appearance."
  (let ((theme (if (jls/macos-dark-mode-p)
                   'modus-vivendi
                 'doom-one-light)))
    (unless (and (memq theme custom-enabled-themes)
                 (= (length custom-enabled-themes) 1))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))))

;; One Double Light is based on Atom One Light.  Doom One Light is its closest
;; maintained Emacs equivalent and has nearly identical base colours.
(use-package doom-themes :ensure nil)

(use-package
 modus-themes
 :ensure nil
 ;; The library ships in Emacs' etc/themes directory.  Themes can be loaded
 ;; from there, but the directory is not on `load-path' by default.
 :init (add-to-list 'load-path (expand-file-name "themes" data-directory))
 (setq
  modus-themes-italic-constructs t
  modus-themes-bold-keywords t)
 :config
 (jls/sync-theme-with-macos)
 (add-hook
  'mac-effective-appearance-change-hook #'jls/sync-theme-with-macos)
 ;; Polling also covers terminal Emacs, which does not receive the Mac port's
 ;; appearance-change hook.
 (run-with-timer 2 2 #'jls/sync-theme-with-macos))

(provide 'jls-appearance)
;;; jls-appearance.el ends here
