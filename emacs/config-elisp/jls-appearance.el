;;; jls-appearance.el --- Appearance configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep the configured light and dark themes in step with the macOS appearance.

;;; Code:

(defun jls/enable-relative-line-numbers ()
  "Enable relative line numbers in the current editing buffer."
  (setq-local display-line-numbers-type 'relative)
  (display-line-numbers-mode 1))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'jls/enable-relative-line-numbers))

;; Show the preferred line-length boundary in programming buffers.
(setq-default fill-column 80)
(setq-default display-fill-column-indicator-character ?│)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

;; Add horizontal breathing room, except where line numbers already provide
;; separation from the left edge.
(setq-default left-margin-width 1)
(setq-default right-margin-width 1)

(defun jls/update-left-margin-for-line-numbers ()
  "Hide left-side spacing when the current buffer displays line numbers."
  (let ((margin-width (if display-line-numbers 0 1))
        (fringe-width (if display-line-numbers 0 nil)))
    (setq-local left-margin-width margin-width)
    (setq-local left-fringe-width fringe-width)
    ;; The visible gap beside line numbers is the left fringe, rather than the
    ;; text margin.  Updating either buffer-local variable only affects windows
    ;; that display the buffer later, so also refresh existing windows.
    (dolist (window (get-buffer-window-list (current-buffer) nil t))
      (set-window-margins window margin-width right-margin-width)
      (set-window-fringes
       window fringe-width right-fringe-width fringes-outside-margins))))

(add-hook
 'display-line-numbers-mode-hook
 #'jls/update-left-margin-for-line-numbers)

;; Also update buffers that already had line numbers when this module was
;; re-evaluated.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when display-line-numbers
      (jls/update-left-margin-for-line-numbers))))

(defun jls/macos-dark-mode-p ()
  "Return non-nil when macOS is using its dark appearance.
Use the Mac port's application state in the GUI.  In a terminal that state is
unavailable, so ask macOS directly instead."
  (let* ((application-state
          (and (fboundp 'mac-application-state)
               (mac-application-state)))
         (appearance (plist-get application-state :appearance)))
    (if appearance
        (string-match-p "Dark" appearance)
      (eq
       0
       (call-process "/usr/bin/defaults"
                     nil
                     nil
                     nil
                     "read"
                     "-g"
                     "AppleInterfaceStyle")))))

(defvar jls/last-macos-dark-mode 'unknown
  "Last macOS appearance observed while synchronising the theme.")

(defun jls/fill-column-indicator-stipple ()
  "Return a one-pixel vertical stipple for the current frame's font width."
  (let* ((width (frame-char-width))
         (x (max 0 (- width 2)))
         (data (make-string (ceiling width 8) 0)))
    (aset data (/ x 8) (lsh 1 (% x 8)))
    (list width 1 data)))

(defun jls/apply-theme-face-overrides (&optional _theme)
  "Keep peripheral faces transparent and draw a continuous column ruler.

THEME is accepted for use in `enable-theme-functions'."
  (set-face-attribute 'fringe nil :background 'unspecified)
  (if (display-graphic-p)
      (progn
        ;; A space painted with a one-pixel stipple is continuous across line
        ;; boxes, unlike a repeated box-drawing glyph.
        (setq-default display-fill-column-indicator-character ?\s)
        (set-face-attribute
         'fill-column-indicator nil
         :background 'unspecified
         :height 'unspecified
         :inherit 'shadow
         :stipple (jls/fill-column-indicator-stipple)))
    ;; Stipples are unavailable in terminal frames, so retain a text fallback.
    (setq-default display-fill-column-indicator-character ?│)
    (set-face-attribute 'fill-column-indicator nil
                        :background 'unspecified
                        :height 'unspecified
                        :inherit 'shadow
                        :stipple nil)))

(defun jls/sync-theme-with-macos ()
  "Update the theme when the macOS appearance changes.
Do not continually enforce the corresponding theme, so commands such as
`consult-theme' can preview and select a different theme between changes."
  (let ((dark-mode (and (jls/macos-dark-mode-p) t)))
    (unless (eq dark-mode jls/last-macos-dark-mode)
      (setq jls/last-macos-dark-mode dark-mode)
      (let ((theme
             (if dark-mode
                 'modus-vivendi
               'doom-one-light)))
        (mapc #'disable-theme custom-enabled-themes)
        (load-theme theme t)))))

;; One Double Light is based on Atom One Light.  Doom One Light is its closest
;; maintained Emacs equivalent and has nearly identical base colours.
(use-package doom-themes :ensure nil)

(use-package
 modus-themes
 :ensure nil
 ;; The library ships in Emacs' etc/themes directory.  Themes can be loaded
 ;; from there, but the directory is not on `load-path' by default.
 :init
 (add-to-list 'load-path (expand-file-name "themes" data-directory))
 (setq
  modus-themes-italic-constructs t
  modus-themes-bold-keywords t)
 :config
 (add-hook 'enable-theme-functions #'jls/apply-theme-face-overrides)
 (jls/sync-theme-with-macos)
 (add-hook
  'mac-effective-appearance-change-hook #'jls/sync-theme-with-macos)
 ;; Polling also covers terminal Emacs, which does not receive the Mac port's
 ;; appearance-change hook.
 (run-with-timer 2 2 #'jls/sync-theme-with-macos))

(provide 'jls-appearance)
;;; jls-appearance.el ends here
