;;; jls-window-management.el --- Leader keys and window splits -*- lexical-binding: t; -*-

;;; Commentary:
;; Window-management bindings for full editor sessions.  Space is a leader in
;; Evil's normal and motion states; split commands choose a direction and then
;; the kind of buffer to open.

;;; Code:

(require 'evil)

(declare-function ace-window "ace-window" (&optional arg))
(declare-function consult-buffer "consult" (&optional sources))
(declare-function dired "dired" (dirname &optional switches))
(declare-function eshell "esh-mode" (&optional arg))
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

(defun jls/open-new-eshell ()
  "Create and select a new Eshell session."
  (eshell t))

(defun jls/open-dired-here ()
  "Open Dired in the current buffer's directory."
  (dired default-directory))

(defun jls/open-new-vterm-then-consult-buffer ()
  "Create a vterm, then choose another buffer to display over it.

The vterm remains in the selected window's buffer history, so quitting the
chosen buffer returns to the vterm."
  (jls/open-new-vterm)
  ;; `vertico-multiform-mode' dispatches on `this-command'.  This command is
  ;; normally reached through a directional split command, so identify the
  ;; nested command explicitly to apply the `consult-buffer' display settings.
  (let ((this-command 'consult-buffer))
    (consult-buffer)))

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

(defun jls/split-eshell-left ()
  "Open a new Eshell session in a window to the left."
  (interactive)
  (jls/split-window-and-open 'left #'jls/open-new-eshell))

(defun jls/split-eshell-below ()
  "Open a new Eshell session in a window below."
  (interactive)
  (jls/split-window-and-open 'below #'jls/open-new-eshell))

(defun jls/split-eshell-above ()
  "Open a new Eshell session in a window above."
  (interactive)
  (jls/split-window-and-open 'above #'jls/open-new-eshell))

(defun jls/split-eshell-right ()
  "Open a new Eshell session in a window to the right."
  (interactive)
  (jls/split-window-and-open 'right #'jls/open-new-eshell))

(defun jls/split-dired-left ()
  "Open Dired in a window to the left."
  (interactive)
  (jls/split-window-and-open 'left #'jls/open-dired-here))

(defun jls/split-dired-below ()
  "Open Dired in a window below."
  (interactive)
  (jls/split-window-and-open 'below #'jls/open-dired-here))

(defun jls/split-dired-above ()
  "Open Dired in a window above."
  (interactive)
  (jls/split-window-and-open 'above #'jls/open-dired-here))

(defun jls/split-dired-right ()
  "Open Dired in a window to the right."
  (interactive)
  (jls/split-window-and-open 'right #'jls/open-dired-here))

(defun jls/split-consult-buffer-left ()
  "Choose a buffer for a new window to the left."
  (interactive)
  (jls/split-window-and-open
   'left #'jls/open-new-vterm-then-consult-buffer))

(defun jls/split-consult-buffer-below ()
  "Choose a buffer for a new window below."
  (interactive)
  (jls/split-window-and-open
   'below #'jls/open-new-vterm-then-consult-buffer))

(defun jls/split-consult-buffer-above ()
  "Choose a buffer for a new window above."
  (interactive)
  (jls/split-window-and-open
   'above #'jls/open-new-vterm-then-consult-buffer))

(defun jls/split-consult-buffer-right ()
  "Choose a buffer for a new window to the right."
  (interactive)
  (jls/split-window-and-open
   'right #'jls/open-new-vterm-then-consult-buffer))

(defvar-keymap jls/split-left-map
  "b"
  #'jls/split-consult-buffer-left
  "d"
  #'jls/split-dired-left
  "e"
  #'jls/split-eshell-left
  "v"
  #'jls/split-vterm-left)
(defvar-keymap jls/split-below-map
  "b"
  #'jls/split-consult-buffer-below
  "d"
  #'jls/split-dired-below
  "e"
  #'jls/split-eshell-below
  "v"
  #'jls/split-vterm-below)
(defvar-keymap jls/split-above-map
  "b"
  #'jls/split-consult-buffer-above
  "d"
  #'jls/split-dired-above
  "e"
  #'jls/split-eshell-above
  "v"
  #'jls/split-vterm-above)
(defvar-keymap jls/split-right-map
  "b"
  #'jls/split-consult-buffer-right
  "d"
  #'jls/split-dired-right
  "e"
  #'jls/split-eshell-right
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

(use-package
 ace-window
 :ensure nil
 :commands ace-window
 :custom
 (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
 (aw-scope 'visible)
 ;; Show labels whenever there is a choice instead of silently behaving like
 ;; `other-window' when only two windows are visible.
 (aw-dispatch-when-more-than 1)
 :custom-face
 (aw-leading-char-face
  ((t (:inherit error
       :weight bold
       :height 2.5
       :inverse-video t
       :box (:line-width 2))))))

(defun jls/visual-select-window ()
  "Select a window visually, then choose what to do with it."
  (interactive)
  (call-interactively #'ace-window)
  (pcase
      (car
       (read-multiple-choice
        "Window action"
        '((?g "go" "Keep the chosen window selected")
          (?x "delete" "Delete the chosen window"))))
    (?g nil)
    (?x (delete-window))))

(defvar-keymap jls/window-map
  "s"
  jls/split-map
  "v"
  #'jls/visual-select-window)

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
  "SPC w v"
  "visual"
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
  "SPC w s h d"
  "dired"
  "SPC w s h e"
  "eshell"
  "SPC w s h v"
  "vterm"
  "SPC w s j b"
  "buffer"
  "SPC w s j d"
  "dired"
  "SPC w s j e"
  "eshell"
  "SPC w s j v"
  "vterm"
  "SPC w s k b"
  "buffer"
  "SPC w s k d"
  "dired"
  "SPC w s k e"
  "eshell"
  "SPC w s k v"
  "vterm"
  "SPC w s l b"
  "buffer"
  "SPC w s l d"
  "dired"
  "SPC w s l e"
  "eshell"
  "SPC w s l v"
  "vterm"))

(provide 'jls-window-management)
;;; jls-window-management.el ends here
