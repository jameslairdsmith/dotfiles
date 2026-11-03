;;; jls-window-management.el --- Leader keys and window splits -*- lexical-binding: t; -*-

;;; Commentary:
;; Window and tab bindings for full editor sessions.  Space is a leader in
;; Evil's normal and motion states; Vim-inspired position commands create
;; windows or tabs and then choose the kind of buffer to open.

;;; Code:

(require 'evil)
(require 'seq)

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

(defun jls/open-in-side-window (side opener)
  "Create a window on frame SIDE and call OPENER in it."
  (let* ((placeholder (generate-new-buffer " *jls-side-window*"))
         (window
          (display-buffer-in-side-window
           placeholder `((side . ,side)))))
    ;; Side windows are dedicated by default.  Temporarily allow OPENER to
    ;; replace the placeholder in this window rather than another one.
    (set-window-dedicated-p window nil)
    (set-window-parameter window 'quit-restore nil)
    (select-window window)
    (unwind-protect
        (funcall opener)
      (when (window-live-p window)
        (set-window-dedicated-p window 'side))
      (when (buffer-live-p placeholder)
        (kill-buffer placeholder)))))

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

(defun jls/open-consult-buffer ()
  "Choose a buffer with Consult using its multiform display settings."
  ;; `vertico-multiform-mode' dispatches on `this-command'.  These openers are
  ;; reached through wrapper commands, so identify the nested command
  ;; explicitly to apply the `consult-buffer' display settings.
  (let ((this-command 'consult-buffer))
    (consult-buffer)))

(defun jls/open-new-vterm-then-consult-buffer ()
  "Create a vterm, then choose another buffer to display over it.

The vterm remains in the selected window's buffer history, so quitting the
chosen buffer returns to the vterm."
  (jls/open-new-vterm)
  (jls/open-consult-buffer))

(defun jls/read-new-tab-opener ()
  "Prompt for and return the function used to populate a new tab."
  (pcase (car
          (read-multiple-choice
           "New tab contents"
           '((?b "buffer" "Choose a buffer with Consult")
             (?d "dired" "Open Dired in the current directory")
             (?e "eshell" "Create a new Eshell session")
             (?v "vterm" "Create a new vterm session"))))
    (?b #'jls/open-consult-buffer)
    (?d #'jls/open-dired-here)
    (?e #'jls/open-new-eshell)
    (?v #'jls/open-new-vterm)))

(defun jls/position-current-tab (anchor placement)
  "Position the current tab relative to ANCHOR according to PLACEMENT."
  (let ((buffer (current-buffer)))
    (unless (eq buffer anchor)
      (let* ((buffers (tab-line-tabs-fixed-window-buffers))
             (buffers (delq buffer (copy-sequence buffers)))
             (anchor-position (seq-position buffers anchor))
             (position
              (pcase placement
                ('start 0)
                ('end (length buffers))
                ('left (or anchor-position 0))
                ('right
                 (if anchor-position
                     (1+ anchor-position)
                   (length buffers)))
                (_ (error "Unknown tab placement: %S" placement))))
             (buffers
              (append
               (seq-take buffers position)
               (list buffer)
               (seq-drop buffers position))))
        (set-window-parameter nil 'tab-line-buffers buffers)
        (set-window-parameter nil 'tab-line-cache nil)
        (force-mode-line-update)))))

(defun jls/add-tab (placement)
  "Add a tab at PLACEMENT and prompt for its contents."
  (let ((anchor (current-buffer))
        (opener (jls/read-new-tab-opener)))
    ;; Initialise the stable tab order before OPENER changes the buffer.
    (tab-line-tabs-fixed-window-buffers)
    (unwind-protect
        (funcall opener)
      (jls/position-current-tab anchor placement))))

(defun jls/add-tab-left ()
  "Add and select a tab to the left of the current tab."
  (interactive)
  (jls/add-tab 'left))

(defun jls/add-tab-right ()
  "Add and select a tab to the right of the current tab."
  (interactive)
  (jls/add-tab 'right))

(defun jls/add-tab-start ()
  "Add and select a tab at the start of the tab line."
  (interactive)
  (jls/add-tab 'start))

(defun jls/add-tab-end ()
  "Add and select a tab at the end of the tab line."
  (interactive)
  (jls/add-tab 'end))

(defun jls/close-current-tab ()
  "Close the current tab by burying its buffer."
  (interactive)
  (bury-buffer)
  (force-mode-line-update))

(use-package
 tab-line
 :ensure nil
 :custom
 (tab-line-tabs-function #'tab-line-tabs-fixed-window-buffers)
 :init (global-tab-line-mode 1))

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

(defun jls/side-consult-buffer-left ()
  "Choose a buffer for a new left side window."
  (interactive)
  (jls/open-in-side-window
   'left #'jls/open-new-vterm-then-consult-buffer))

(defun jls/side-dired-left ()
  "Open Dired in a new left side window."
  (interactive)
  (jls/open-in-side-window 'left #'jls/open-dired-here))

(defun jls/side-eshell-left ()
  "Open a new Eshell session in a left side window."
  (interactive)
  (jls/open-in-side-window 'left #'jls/open-new-eshell))

(defun jls/side-vterm-left ()
  "Open a new vterm session in a left side window."
  (interactive)
  (jls/open-in-side-window 'left #'jls/open-new-vterm))

(defun jls/side-consult-buffer-right ()
  "Choose a buffer for a new right side window."
  (interactive)
  (jls/open-in-side-window
   'right #'jls/open-new-vterm-then-consult-buffer))

(defun jls/side-dired-right ()
  "Open Dired in a new right side window."
  (interactive)
  (jls/open-in-side-window 'right #'jls/open-dired-here))

(defun jls/side-eshell-right ()
  "Open a new Eshell session in a right side window."
  (interactive)
  (jls/open-in-side-window 'right #'jls/open-new-eshell))

(defun jls/side-vterm-right ()
  "Open a new vterm session in a right side window."
  (interactive)
  (jls/open-in-side-window 'right #'jls/open-new-vterm))

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

(defvar-keymap jls/side-left-map
  "b"
  #'jls/side-consult-buffer-left
  "d"
  #'jls/side-dired-left
  "e"
  #'jls/side-eshell-left
  "v"
  #'jls/side-vterm-left)
(defvar-keymap jls/side-right-map
  "b"
  #'jls/side-consult-buffer-right
  "d"
  #'jls/side-dired-right
  "e"
  #'jls/side-eshell-right
  "v"
  #'jls/side-vterm-right)

(use-package
 ace-window
 :ensure nil
 :commands ace-window
 :custom (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)) (aw-scope 'visible)
 ;; Show labels whenever there is a choice instead of silently behaving like
 ;; `other-window' when only two windows are visible.
 (aw-dispatch-when-more-than 1)
 :custom-face
 (aw-leading-char-face
  ((t
    (:inherit
     error
     :weight bold
     :height 2.5
     :inverse-video t
     :box (:line-width 2))))))

(defun jls/visual-select-window ()
  "Select a window visually, then choose what to do with it."
  (interactive)
  (call-interactively #'ace-window)
  (pcase (car
          (read-multiple-choice
           "Window action"
           '((?g "go" "Keep the chosen window selected")
             (?x "delete" "Delete the chosen window"))))
    (?g nil)
    (?x (delete-window))))

(defun jls/close-current-window ()
  "Delete the selected window when it can be safely deleted."
  (interactive)
  (if (eq (window-deletable-p) t)
      (delete-window)
    (message "The current window cannot be deleted")))

(defvar-keymap jls/window-map
  "i"
  jls/split-left-map
  "a"
  jls/split-right-map
  "I"
  jls/side-left-map
  "A"
  jls/side-right-map
  "o"
  jls/split-below-map
  "O"
  jls/split-above-map
  "v"
  #'jls/visual-select-window
  "x"
  #'jls/close-current-window)

(defvar-keymap jls/tab-map
  "i"
  #'jls/add-tab-left
  "a"
  #'jls/add-tab-right
  "I"
  #'jls/add-tab-start
  "A"
  #'jls/add-tab-end
  "x"
  #'jls/close-current-tab)

(defvar-keymap jls/leader-map
  "b"
  #'consult-buffer
  "t"
  jls/tab-map
  "w"
  jls/window-map)

(evil-define-key '(normal motion) 'global (kbd "SPC") jls/leader-map)

(use-package
 which-key
 :ensure nil
 :init (which-key-mode 1)
 :config
 (which-key-add-key-based-replacements
  "SPC b"
  "buffer"
  "SPC t"
  "tab"
  "SPC t i"
  "insert left"
  "SPC t a"
  "append right"
  "SPC t I"
  "insert at start"
  "SPC t A"
  "append at end"
  "SPC t x"
  "close"
  "SPC w"
  "window"
  "SPC w v"
  "visual"
  "SPC w x"
  "close"
  "SPC w i"
  "insert left"
  "SPC w a"
  "append right"
  "SPC w I"
  "left side"
  "SPC w A"
  "right side"
  "SPC w o"
  "open below"
  "SPC w O"
  "open above")
 (dolist (prefix
          '("SPC w i"
            "SPC w a"
            "SPC w I"
            "SPC w A"
            "SPC w o"
            "SPC w O"))
   (which-key-add-key-based-replacements
    (concat prefix " b")
    "buffer"
    (concat prefix " d")
    "dired"
    (concat prefix " e")
    "eshell"
    (concat prefix " v")
    "vterm")))

(provide 'jls-window-management)
;;; jls-window-management.el ends here
