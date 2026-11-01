;;; jls-window-management.el --- Leader keys and window splits -*- lexical-binding: t; -*-

;;; Commentary:
;; Window-management bindings for full editor sessions.  Space is a leader in
;; Evil's normal and motion states; split commands choose a direction and then
;; the kind of buffer to open.

;;; Code:

(require 'evil)

(declare-function consult-buffer "consult" (&optional sources))
(declare-function vterm "vterm" (&optional arg))

(defun jls/split-window-and-open (side opener)
  "Split the selected window on SIDE and call OPENER in the new window."
  (let ((new-window (split-window nil nil side)))
    (select-window new-window)
    (funcall opener)))

(defun jls/open-new-vterm ()
  "Create and select a new vterm session."
  ;; Without a non-numeric argument, `vterm' reuses its existing buffer.
  ;; Showing one live terminal in differently sized windows can cause its
  ;; process and the windows to repeatedly resize each other and hang Emacs.
  (vterm t))

(defun jls/split-vterm-left ()
  "Open a new vterm in a window to the left."
  (interactive)
  (jls/split-window-and-open 'left #'jls/open-new-vterm))

(defun jls/split-vterm-below ()
  "Open a new vterm in a window below."
  (interactive)
  (jls/split-window-and-open 'below #'jls/open-new-vterm))

(defun jls/split-vterm-above ()
  "Open a new vterm in a window above."
  (interactive)
  (jls/split-window-and-open 'above #'jls/open-new-vterm))

(defun jls/split-vterm-right ()
  "Open a new vterm in a window to the right."
  (interactive)
  (jls/split-window-and-open 'right #'jls/open-new-vterm))

(defun jls/split-consult-buffer-left ()
  "Choose a buffer for a new window to the left."
  (interactive)
  (jls/split-window-and-open 'left #'consult-buffer))

(defun jls/split-consult-buffer-below ()
  "Choose a buffer for a new window below."
  (interactive)
  (jls/split-window-and-open 'below #'consult-buffer))

(defun jls/split-consult-buffer-above ()
  "Choose a buffer for a new window above."
  (interactive)
  (jls/split-window-and-open 'above #'consult-buffer))

(defun jls/split-consult-buffer-right ()
  "Choose a buffer for a new window to the right."
  (interactive)
  (jls/split-window-and-open 'right #'consult-buffer))

(defvar-keymap jls/split-left-map
  "b"
  #'jls/split-consult-buffer-left
  "v"
  #'jls/split-vterm-left)
(defvar-keymap jls/split-below-map
  "b"
  #'jls/split-consult-buffer-below
  "v"
  #'jls/split-vterm-below)
(defvar-keymap jls/split-above-map
  "b"
  #'jls/split-consult-buffer-above
  "v"
  #'jls/split-vterm-above)
(defvar-keymap jls/split-right-map
  "b"
  #'jls/split-consult-buffer-right
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

(defvar-keymap jls/window-map
  "s"
  jls/split-map)

(defvar-keymap jls/leader-map
  "w"
  jls/window-map)

(evil-define-key '(normal motion) 'global (kbd "SPC") jls/leader-map)

(use-package
 which-key
 :ensure nil
 :init (which-key-mode 1)
 :config
 (which-key-add-key-based-replacements
  "SPC w"
  "window"
  "SPC w s"
  "split"
  "SPC w s h"
  "left"
  "SPC w s j"
  "below"
  "SPC w s k"
  "above"
  "SPC w s l"
  "right"
  "SPC w s h b"
  "buffer"
  "SPC w s h v"
  "vterm"
  "SPC w s j b"
  "buffer"
  "SPC w s j v"
  "vterm"
  "SPC w s k b"
  "buffer"
  "SPC w s k v"
  "vterm"
  "SPC w s l b"
  "buffer"
  "SPC w s l v"
  "vterm"))

(provide 'jls-window-management)
;;; jls-window-management.el ends here
