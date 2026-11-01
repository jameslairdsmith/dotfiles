;;; jls-window-management.el --- Leader keys and window splits -*- lexical-binding: t; -*-

;;; Commentary:
;; Window-management bindings for full editor sessions.  Space is a leader in
;; Evil's normal and motion states; split commands choose a direction and then
;; the kind of buffer to open.

;;; Code:

(require 'evil)

(declare-function vterm "vterm" (&optional arg))

(defun jls/split-window-and-open (side opener)
  "Split the selected window on SIDE and call OPENER in the new window."
  (let ((new-window (split-window nil nil side)))
    (select-window new-window)
    (funcall opener)))

(defun jls/split-vterm-left ()
  "Open a new vterm in a window to the left."
  (interactive)
  (jls/split-window-and-open 'left #'vterm))

(defun jls/split-vterm-below ()
  "Open a new vterm in a window below."
  (interactive)
  (jls/split-window-and-open 'below #'vterm))

(defun jls/split-vterm-above ()
  "Open a new vterm in a window above."
  (interactive)
  (jls/split-window-and-open 'above #'vterm))

(defun jls/split-vterm-right ()
  "Open a new vterm in a window to the right."
  (interactive)
  (jls/split-window-and-open 'right #'vterm))

(defvar-keymap jls/split-left-map
  "v"
  #'jls/split-vterm-left)
(defvar-keymap jls/split-below-map
  "v"
  #'jls/split-vterm-below)
(defvar-keymap jls/split-above-map
  "v"
  #'jls/split-vterm-above)
(defvar-keymap jls/split-right-map
  "v"
  #'jls/split-vterm-right)

(defvar-keymap jls/split-map
  "h"
  jls/split-left-map
  "j"
  jls/split-below-map
  "k"
  jls/split-above-map
  "l"
  jls/split-right-map)

(defvar-keymap jls/leader-map
  "s"
  jls/split-map)

(evil-define-key '(normal motion) 'global (kbd "SPC") jls/leader-map)

(use-package
 which-key
 :ensure nil
 :init (which-key-mode 1)
 :config
 (which-key-add-key-based-replacements
  "SPC s"
  "split"
  "SPC s h"
  "left"
  "SPC s j"
  "below"
  "SPC s k"
  "above"
  "SPC s l"
  "right"
  "SPC s h v"
  "vterm"
  "SPC s j v"
  "vterm"
  "SPC s k v"
  "vterm"
  "SPC s l v"
  "vterm"))

(provide 'jls-window-management)
;;; jls-window-management.el ends here
