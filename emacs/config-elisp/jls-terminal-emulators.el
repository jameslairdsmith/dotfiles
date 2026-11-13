;;; jls-terminal-emulators.el --- Terminal emulators -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal emulators used from full editor sessions.

;;; Code:

(require 'seq)

(declare-function eat-self-input "eat" (n &optional event))
(declare-function eat-term-send-string "eat" (terminal string))
(declare-function evil-collection-init "evil-collection"
                  (&optional modes))
(declare-function jls/current-project-root "jls-projects" ())
(declare-function vterm-send-escape "vterm" ())

(defvar eat-terminal)
(defvar eshell-last-output-end)

(defun jls/window-has-other-buffer-tabs-p (window buffer)
  "Return non-nil if WINDOW has a buffer-history tab besides BUFFER."
  (seq-some
   (lambda (candidate)
     (and (buffer-live-p candidate) (not (eq candidate buffer))))
   (append
    (mapcar #'car (window-prev-buffers window))
    (window-next-buffers window))))

(defun jls/delete-deletable-buffer-windows (buffer)
  "Delete deletable windows displaying sole-tab BUFFER."
  (when (buffer-live-p buffer)
    (dolist (window (get-buffer-window-list buffer nil t))
      ;; The terminal exit hooks run before their buffers are killed.  Preserve
      ;; a window that has other tabs: killing BUFFER will make Emacs select one
      ;; from its history.  Delete only terminal-only windows, while still not
      ;; deleting a frame when its sole window displays the terminal.
      (when (and (eq (window-deletable-p window) t)
                 (not
                  (jls/window-has-other-buffer-tabs-p window buffer)))
        (delete-window window)))))

(defun jls/vterm-delete-windows-on-exit (buffer _event)
  "Delete deletable windows displaying the exited vterm BUFFER."
  (jls/delete-deletable-buffer-windows buffer))

(defun jls/eat-finish-exit-cleanup (buffer windows)
  "Kill exited Eat BUFFER, then delete its terminal-only WINDOWS."
  (when (buffer-live-p buffer)
    (kill-buffer buffer))
  (dolist (window windows)
    ;; Recheck deletability in case the frame layout changed while the timer was
    ;; pending.  In particular, never delete a frame's sole window.
    (when (and (window-live-p window)
               (eq (window-deletable-p window) t))
      (delete-window window))))

(defun jls/eat-clean-up-on-exit (_process)
  "Arrange to clean up the current Eat buffer after its exit hooks finish."
  (let ((buffer (current-buffer))
        (windows
         (seq-filter
          (lambda (window)
            (and (eq (window-deletable-p window) t)
                 (not
                  (jls/window-has-other-buffer-tabs-p window
                                                      (current-buffer)))))
          (get-buffer-window-list (current-buffer) nil t))))
    ;; Eat runs its exit hooks from the process sentinel.  Defer killing the
    ;; buffer and deleting windows until the complete hook sequence returns;
    ;; changing the selected window during Eat's own hook processing can make
    ;; a later hook act on the wrong buffer.
    (run-at-time 0 nil #'jls/eat-finish-exit-cleanup buffer windows)))

(defun jls/eshell-delete-windows-on-exit ()
  "Delete deletable windows displaying the exiting Eshell buffer."
  (jls/delete-deletable-buffer-windows (current-buffer)))

(defun jls/eshell-return-to-input-on-insert ()
  "Move from Eshell scrollback to the active input on entering insert state."
  (when (and (derived-mode-p 'eshell-mode)
             (markerp eshell-last-output-end)
             (< (point) eshell-last-output-end))
    (goto-char (point-max))))

(defun jls/eat-send-escape-to-tui ()
  "Send Escape to the terminal application running in Eat."
  (interactive)
  (eat-self-input 1 'escape))

(defun jls/eat-send-backspace-to-tui ()
  "Send the backspace advertised by Eat's terminal type to its application."
  (interactive)
  ;; Eat encodes its `backspace' event as DEL (Control-?), but the
  ;; xterm-256color terminfo selected below advertises Control-H.  Fish follows
  ;; terminfo strictly, unlike Bash's Readline, so send the advertised byte.
  (eat-term-send-string eat-terminal "\C-h"))

(defun jls/eshell-send-escape-to-tui ()
  "Send Escape to an Eat-managed TUI from Evil normal state."
  (interactive)
  (if (bound-and-true-p eat-terminal)
      (jls/eat-send-escape-to-tui)
    (keyboard-escape-quit)))

(defun jls/evil-collection-eshell-setup ()
  "Configure Evil Collection behaviour in Eshell."
  (evil-define-key
   'insert
   eshell-mode-map
   (kbd "RET")
   #'eshell-send-input
   (kbd "<return>")
   #'eshell-send-input
   (kbd "C-m")
   #'eshell-send-input)
  (add-hook 'evil-insert-state-entry-hook
            #'jls/eshell-return-to-input-on-insert
            nil
            t)
  (add-hook 'evil-replace-state-entry-hook
            #'jls/eshell-return-to-input-on-insert
            nil
            t))

(add-hook 'eshell-exit-hook #'jls/eshell-delete-windows-on-exit)

(defun jls/terminal-use-project-directory (function &rest arguments)
  "Call terminal FUNCTION with the current project as its working directory.

Use the selected buffer's directory when the current Tabspaces workspace is
not associated with a project.  Pass ARGUMENTS unchanged to FUNCTION."
  (let* ((project-root
          (and (fboundp #'jls/current-project-root)
               (jls/current-project-root)))
         (default-directory
          (if project-root
              (file-name-as-directory project-root)
            default-directory)))
    (apply function arguments)))

(use-package
 vterm
 :ensure nil
 :commands vterm
 :init (add-hook 'vterm-exit-functions #'jls/vterm-delete-windows-on-exit)
 ;; Keep vterm's refresh delay non-nil.  Nil refreshes after every output
 ;; update, which can overwhelm Emacs's redisplay when several vterms run.
 :custom (vterm-timer-delay 0.1)
 :config
 (advice-add #'vterm :around #'jls/terminal-use-project-directory))

(use-package
 evil-collection
 :ensure nil
 :after (evil vterm)
 :demand t
 :hook (vterm-mode . evil-local-mode)
 :config (evil-collection-init 'vterm)
 ;; Evil still consumes the first Escape in insert state to enter normal state.
 ;; Once there, subsequent Escapes must reach the TUI rather than repeatedly
 ;; invoking Evil's normal-state escape behaviour.
 (evil-define-key
  'normal vterm-mode-map (kbd "<escape>") #'vterm-send-escape))

(use-package
 eshell
 :ensure nil
 :commands eshell
 :config
 (advice-add #'eshell :around #'jls/terminal-use-project-directory))

(use-package
 evil-collection
 :ensure nil
 :after (evil eshell)
 :demand t
 :hook
 (eshell-mode . evil-local-mode)
 (eshell-mode . jls/evil-collection-eshell-setup)
 :config (evil-collection-init 'eshell)
 ;; As in vterm, the first Escape leaves insert state.  In normal state, pass
 ;; later Escapes to an active Eat terminal; at an ordinary Eshell prompt the
 ;; wrapper retains Emacs' normal escape behaviour.
 (evil-define-key
  'normal
  eshell-mode-map
  (kbd "<escape>")
  #'jls/eshell-send-escape-to-tui))

(use-package
 eat
 :ensure nil
 :commands (eat eat-project eat-eshell-mode)
 :init
 (add-hook 'eshell-load-hook #'eat-eshell-mode)
 (add-hook 'eat-exit-hook #'jls/eat-clean-up-on-exit)
 :custom
 ;; Cleanup is deferred until Eat has finished running all its exit hooks so
 ;; that deleting the selected window cannot redirect a later hook to another
 ;; buffer.
 (eat-kill-buffer-on-exit nil)
 ;; Prevent commands such as `top' from bypassing Eat via Eshell's old `term'
 ;; path; Eat provides terminal emulation directly in the Eshell buffer.
 (eshell-visual-commands nil)
 ;; macOS's system ncurses cannot read Eat's Nix-built `eat-truecolor'
 ;; terminfo entry.  Use a terminal type understood by both macOS and Nix.
 ;; This limits applications to the 256-colour palette instead of advertising
 ;; true-colour support; see the corresponding entry in emacs/TODO.md.
 (eat-term-name "xterm-256color")
 (eat-minimum-latency 0.008)
 (eat-maximum-latency 0.033)
 :config
 (advice-add #'eat :around #'jls/terminal-use-project-directory))

(use-package
 evil-collection
 :ensure nil
 :after (evil eat)
 :demand t
 :hook (eat-mode . evil-local-mode)
 :config
 (evil-collection-init 'eat)
 ;; Evil's insert-state backspace binding otherwise shadows Eat.  Also send
 ;; the byte advertised by our terminal type rather than Eat's hard-coded DEL.
 ;; Cover both forms in which Emacs may report the physical key.
 (evil-define-key
  'insert
  eat-mode-map
  (kbd "DEL")
  #'jls/eat-send-backspace-to-tui
  (kbd "<backspace>")
  #'jls/eat-send-backspace-to-tui)
 ;; The first Escape leaves insert state.  Once in normal state, pass later
 ;; Escapes through to the terminal application, matching vterm and Eshell.
 (evil-define-key
  'normal
  eat-mode-map
  (kbd "<escape>")
  #'jls/eat-send-escape-to-tui))

(provide 'jls-terminal-emulators)
;;; jls-terminal-emulators.el ends here
