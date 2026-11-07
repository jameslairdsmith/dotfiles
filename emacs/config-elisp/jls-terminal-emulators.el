;;; jls-terminal-emulators.el --- Terminal emulators -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal emulators used from full editor sessions.

;;; Code:

(require 'seq)

(declare-function eat-self-input "eat" (n &optional event))
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

(defun jls/eshell-delete-windows-on-exit ()
  "Delete deletable windows displaying the exiting Eshell buffer."
  (jls/delete-deletable-buffer-windows (current-buffer)))

(defun jls/eshell-return-to-input-on-insert ()
  "Move from Eshell scrollback to the active input on entering insert state."
  (when (and (derived-mode-p 'eshell-mode)
             (markerp eshell-last-output-end)
             (< (point) eshell-last-output-end))
    (goto-char (point-max))))

(defun jls/eshell-send-escape-to-tui ()
  "Send Escape to an Eat-managed TUI from Evil normal state."
  (interactive)
  (if (bound-and-true-p eat-terminal)
      (eat-self-input 1 'escape)
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

(defun jls/vterm-use-project-directory (function &rest arguments)
  "Call vterm FUNCTION with the current project as its working directory.

Use the selected buffer's directory when the current Tabspaces workspace is
not associated with a project.  Pass ARGUMENTS unchanged to FUNCTION."
  (let ((default-directory
         (or (and (fboundp #'jls/current-project-root)
                  (jls/current-project-root))
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
 (advice-add #'vterm :around #'jls/vterm-use-project-directory))

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
 :init (add-hook 'eshell-load-hook #'eat-eshell-mode)
 :custom
 ;; Prevent commands such as `top' from bypassing Eat via Eshell's old `term'
 ;; path; Eat provides terminal emulation directly in the Eshell buffer.
 (eshell-visual-commands nil)
 ;; macOS's system ncurses cannot read Eat's Nix-built `eat-truecolor'
 ;; terminfo entry.  Use a terminal type understood by both macOS and Nix.
 ;; This limits applications to the 256-colour palette instead of advertising
 ;; true-colour support; see the corresponding entry in emacs/TODO.md.
 (eat-term-name "xterm-256color")
 (eat-minimum-latency 0.008)
 (eat-maximum-latency 0.033))

(provide 'jls-terminal-emulators)
;;; jls-terminal-emulators.el ends here
