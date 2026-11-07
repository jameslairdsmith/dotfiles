;;; jls-window-management.el --- Leader keys and window splits -*- lexical-binding: t; -*-

;;; Commentary:
;; Window and tab bindings for full editor sessions.  Space is a leader in
;; Evil's normal and motion states; Vim-inspired position commands create
;; windows or tabs and then choose the kind of buffer to open.

;;; Code:

(require 'cl-lib)
(require 'evil)
(require 'seq)

(declare-function ace-window "ace-window" (&optional arg))
(declare-function consult-buffer "consult" (&optional sources))
(declare-function jls/consult-project-buffer "jls-projects" ())
(declare-function jls/consult-project-file "jls-projects" ())
(declare-function dired "dired" (dirname &optional switches))
(declare-function eshell "esh-mode" (&optional arg))
(declare-function vterm "vterm" (&optional arg))

(defvar aw-dispatch-alist)
(defvar aw-ignore-on)
(defvar aw-make-frame-char)

;; `tab-line-mode' derives its tabs from each window's buffer history rather
;; than maintaining independent tab objects.  Remove incidental buffers from
;; both histories so they do not become tabs merely because Emacs displayed
;; them while setting up a window.
(defun jls/remove-buffer-from-window-history (window buffer)
  "Remove BUFFER from WINDOW's buffer and tab history."
  (when (and (window-live-p window)
             (not (eq buffer (window-buffer window))))
    (set-window-prev-buffers
     window (assq-delete-all buffer (window-prev-buffers window)))
    (set-window-next-buffers
     window (delq buffer (window-next-buffers window)))
    (set-window-parameter
     window
     'tab-line-buffers
     (delq buffer (window-parameter window 'tab-line-buffers)))
    (set-window-parameter window 'tab-line-cache nil)
    (force-mode-line-update)))

(defun jls/reset-current-window-buffer-history ()
  "Keep only the current buffer in the selected window's history."
  (let ((window (selected-window))
        (buffer (current-buffer)))
    (set-window-prev-buffers window nil)
    (set-window-next-buffers window nil)
    (set-window-parameter window 'tab-line-buffers (list buffer))
    (set-window-parameter window 'tab-line-cache nil)
    (force-mode-line-update)))

;; Emacs shows `*scratch*' before Dashboard replaces it during startup.  Reset
;; the window history afterwards so `*scratch*' remains available globally but
;; does not appear as a tab that the user never opened.
(add-hook
 'dashboard-after-initialize-hook
 #'jls/reset-current-window-buffer-history)

(defun jls/split-window-and-open (side opener)
  "Split the selected window on SIDE and call OPENER in the new window."
  (let ((inherited-buffer (current-buffer))
        (new-window (split-window nil nil side)))
    ;; A split initially displays the original window's buffer.  Let OPENER use
    ;; that buffer's context (notably `default-directory'), then remove the
    ;; inherited buffer unless OPENER deliberately leaves it selected.  The
    ;; cleanup also runs when an interactive opener is quit.
    (select-window new-window)
    (unwind-protect
        (funcall opener)
      (jls/remove-buffer-from-window-history
       new-window inherited-buffer))))

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

(defun jls/open-consult-project-buffer ()
  "Choose a buffer from the current project workspace with Consult."
  (let ((this-command 'consult-buffer))
    (jls/consult-project-buffer)))

(defun jls/open-new-vterm-then-consult-buffer ()
  "Create a vterm, then choose another buffer to display over it.

The vterm remains in the selected window's buffer history, so quitting the
chosen buffer returns to the vterm."
  (jls/open-new-vterm)
  (jls/open-consult-buffer))

(defun jls/open-new-vterm-then-consult-project-buffer ()
  "Create a vterm, then choose a project buffer to display over it."
  (jls/open-new-vterm)
  (jls/open-consult-project-buffer))

(defun jls/open-new-vterm-then-consult-project-file ()
  "Create a vterm, then choose a project file to display over it."
  (jls/open-new-vterm)
  (jls/consult-project-file))

(defun jls/read-multiple-choice (prompt choices)
  "Read one of CHOICES using PROMPT, with Escape as an explicit quit key."
  (let ((read-event-function (symbol-function #'read-event)))
    (cl-letf (((symbol-function #'read-event)
               (lambda (&rest arguments)
                 (let ((event (apply read-event-function arguments)))
                   (if (memq event '(escape ?\e))
                       (keyboard-quit)
                     event)))))
      (read-multiple-choice prompt choices))))

(defun jls/read-new-tab-opener ()
  "Prompt for and return the function used to populate a new tab."
  (pcase (car
          (jls/read-multiple-choice
           "New tab contents"
           '((?b "project buffer" "Choose a buffer from the current project")
             (?B "buffer" "Choose a buffer with Consult")
             (?d "dired" "Open Dired in the current directory")
             (?e "eshell" "Create a new Eshell session")
             (?f "project file" "Choose a file from the current project")
             (?v "vterm" "Create a new vterm session"))))
    (?b #'jls/open-consult-project-buffer)
    (?B #'jls/open-consult-buffer)
    (?d #'jls/open-dired-here)
    (?e #'jls/open-new-eshell)
    (?f #'jls/consult-project-file)
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

(defun jls/tab-line-format-when-multiple
    (format-function &rest arguments)
  "Call FORMAT-FUNCTION with ARGUMENTS when multiple tabs are present."
  (when (> (length (funcall tab-line-tabs-function)) 1)
    (apply format-function arguments)))

(use-package
 tab-line
 :ensure nil
 :custom (tab-line-tabs-function #'tab-line-tabs-fixed-window-buffers)
 :config
 (advice-add
  #'tab-line-format
  :around #'jls/tab-line-format-when-multiple)
 (global-tab-line-mode 1))

(use-package
 tabgo
 :ensure nil
 :commands tabgo-line
 :custom (tabgo-tab-line-keys "asdfghjkl"))

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

(defun jls/split-project-file-left ()
  "Choose a project file for a new window to the left."
  (interactive)
  (jls/split-window-and-open
   'left #'jls/open-new-vterm-then-consult-project-file))

(defun jls/split-project-file-below ()
  "Choose a project file for a new window below."
  (interactive)
  (jls/split-window-and-open
   'below #'jls/open-new-vterm-then-consult-project-file))

(defun jls/split-project-file-above ()
  "Choose a project file for a new window above."
  (interactive)
  (jls/split-window-and-open
   'above #'jls/open-new-vterm-then-consult-project-file))

(defun jls/split-project-file-right ()
  "Choose a project file for a new window to the right."
  (interactive)
  (jls/split-window-and-open
   'right #'jls/open-new-vterm-then-consult-project-file))

(defun jls/split-project-buffer-left ()
  "Choose a project buffer for a new window to the left."
  (interactive)
  (jls/split-window-and-open
   'left #'jls/open-new-vterm-then-consult-project-buffer))

(defun jls/split-project-buffer-below ()
  "Choose a project buffer for a new window below."
  (interactive)
  (jls/split-window-and-open
   'below #'jls/open-new-vterm-then-consult-project-buffer))

(defun jls/split-project-buffer-above ()
  "Choose a project buffer for a new window above."
  (interactive)
  (jls/split-window-and-open
   'above #'jls/open-new-vterm-then-consult-project-buffer))

(defun jls/split-project-buffer-right ()
  "Choose a project buffer for a new window to the right."
  (interactive)
  (jls/split-window-and-open
   'right #'jls/open-new-vterm-then-consult-project-buffer))

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

(defun jls/side-project-file-left ()
  "Choose a project file for a new left side window."
  (interactive)
  (jls/open-in-side-window
   'left #'jls/open-new-vterm-then-consult-project-file))

(defun jls/side-project-file-right ()
  "Choose a project file for a new right side window."
  (interactive)
  (jls/open-in-side-window
   'right #'jls/open-new-vterm-then-consult-project-file))

(defun jls/side-project-buffer-left ()
  "Choose a project buffer for a new left side window."
  (interactive)
  (jls/open-in-side-window
   'left #'jls/open-new-vterm-then-consult-project-buffer))

(defun jls/side-project-buffer-right ()
  "Choose a project buffer for a new right side window."
  (interactive)
  (jls/open-in-side-window
   'right #'jls/open-new-vterm-then-consult-project-buffer))

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
  #'jls/split-project-buffer-left
  "B"
  #'jls/split-consult-buffer-left
  "d"
  #'jls/split-dired-left
  "e"
  #'jls/split-eshell-left
  "f"
  #'jls/split-project-file-left
  "v"
  #'jls/split-vterm-left)
(defvar-keymap jls/split-below-map
  "b"
  #'jls/split-project-buffer-below
  "B"
  #'jls/split-consult-buffer-below
  "d"
  #'jls/split-dired-below
  "e"
  #'jls/split-eshell-below
  "f"
  #'jls/split-project-file-below
  "v"
  #'jls/split-vterm-below)
(defvar-keymap jls/split-above-map
  "b"
  #'jls/split-project-buffer-above
  "B"
  #'jls/split-consult-buffer-above
  "d"
  #'jls/split-dired-above
  "e"
  #'jls/split-eshell-above
  "f"
  #'jls/split-project-file-above
  "v"
  #'jls/split-vterm-above)
(defvar-keymap jls/split-right-map
  "b"
  #'jls/split-project-buffer-right
  "B"
  #'jls/split-consult-buffer-right
  "d"
  #'jls/split-dired-right
  "e"
  #'jls/split-eshell-right
  "f"
  #'jls/split-project-file-right
  "v"
  #'jls/split-vterm-right)

(defvar-keymap jls/side-left-map
  "b"
  #'jls/side-project-buffer-left
  "B"
  #'jls/side-consult-buffer-left
  "d"
  #'jls/side-dired-left
  "e"
  #'jls/side-eshell-left
  "f"
  #'jls/side-project-file-left
  "v"
  #'jls/side-vterm-left)
(defvar-keymap jls/side-right-map
  "b"
  #'jls/side-project-buffer-right
  "B"
  #'jls/side-consult-buffer-right
  "d"
  #'jls/side-dired-right
  "e"
  #'jls/side-eshell-right
  "f"
  #'jls/side-project-file-right
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
  "Select and go to a window visually without offering other actions."
  (interactive)
  (let ((aw-dispatch-alist nil)
        (aw-ignore-on nil)
        (aw-make-frame-char nil)
        (ignore-window-parameters t))
    (ace-window 1)))

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
  "v"
  #'tabgo-line
  "x"
  #'jls/close-current-tab)

(defvar-keymap jls/leader-map
  "b"
  #'consult-buffer
  "p"
  jls/project-map
  "t"
  jls/tab-map
  "w"
  jls/window-map)

;; Escape should abandon a partially entered leader sequence at any depth rather
;; than begin Emacs' Meta prefix.  GUI Emacs reports the Escape function key as
;; <escape>, while terminal Emacs reports the ASCII ESC event, so bind both in
;; every custom prefix map.
(dolist (map
         (list
          jls/leader-map
          jls/project-map
          jls/window-map
          jls/tab-map
          jls/split-left-map
          jls/split-right-map
          jls/split-below-map
          jls/split-above-map
          jls/side-left-map
          jls/side-right-map))
  (dolist (key '("<escape>" "ESC"))
    (keymap-set map key #'keyboard-quit)))

(evil-define-key '(normal motion) 'global (kbd "SPC") jls/leader-map)

(defun jls/dired-bind-leader (&rest _arguments)
  "Make Space open the leader map in Evil's Dired normal state."
  (evil-collection-define-key
   'normal 'dired-mode-map (kbd "SPC") jls/leader-map))

;; Evil Collection deliberately gives Dired a local Space binding, which takes
;; precedence over the global leader.  Reapply the leader after Dired's Evil
;; Collection setup, including when that setup runs after this module loads.
(with-eval-after-load 'evil-collection-dired
  (advice-add
   #'evil-collection-dired-setup
   :after #'jls/dired-bind-leader)
  (jls/dired-bind-leader))

(use-package
 which-key
 :ensure nil
 :init (which-key-mode 1)
 :config
 (which-key-add-key-based-replacements
  "SPC b"
  "buffer"
  "SPC p"
  "project"
  "SPC p o"
  "open"
  "SPC p s"
  "switch"
  "SPC p x"
  "close"
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
  "SPC t v"
  "visual"
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
