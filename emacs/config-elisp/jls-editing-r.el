;;; jls-editing-r.el --- R editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Provide R major-mode support through ESS.  Evil is enabled automatically
;; because `ess-r-mode' derives from `prog-mode'.

;;; Code:

(require 'project)

(declare-function jls/delete-deletable-buffer-windows
                  "jls-terminal-emulators"
                  (buffer))

(defun jls/ess-project-root ()
  "Return the current workspace or Project project root, if any."
  (or (and (fboundp #'jls/current-project-root)
           (jls/current-project-root))
      (when-let ((project (project-current nil)))
        (project-root project))))

(defun jls/ess-r-use-project-directory (function &rest arguments)
  "Call R-starting FUNCTION from the project root when one is available.

Pass ARGUMENTS unchanged.  Preserve ESS's directory prompt outside projects."
  (if-let ((root (jls/ess-project-root)))
      (let ((ess-startup-directory
             (file-name-as-directory (expand-file-name root)))
            (ess-ask-for-ess-directory nil))
        (apply function arguments))
    (apply function arguments)))

(defun jls/ess-r-object-completion-when-ready ()
  "Complete R objects without failing while the ESS process is busy."
  (condition-case error-data
      (ess-r-object-completion)
    (user-error
     (if (string-prefix-p
          "ESS process not ready" (error-message-string error-data))
         nil
       (signal (car error-data) (cdr error-data))))))

(defun jls/ess-r-package-completion-after-prefix ()
  "Complete R packages only when there is a symbol before point."
  (when (ess-symbol-start)
    (ess-r-package-completion)))

(defun jls/ess-setup-completion ()
  "Make ESS completion safe for automatic completion frontends."
  (setq-local completion-at-point-functions
              (mapcar
               (lambda (function)
                 (pcase function
                   ('ess-r-object-completion
                    #'jls/ess-r-object-completion-when-ready)
                   ('ess-r-package-completion
                    #'jls/ess-r-package-completion-after-prefix)
                   (_ function)))
               completion-at-point-functions)))

(defun jls/ess-insert-native-pipe ()
  "Insert R's native pipe operator with context-sensitive spacing.

Put one space between the pipe and text on the same line.  Do not add a space
on a side with no text, and preserve indentation before an otherwise empty
insertion point."
  (interactive)
  (when (derived-mode-p 'inferior-ess-r-mode)
    (when-let ((process (get-buffer-process (current-buffer))))
      (when (< (point) (marker-position (process-mark process)))
        (goto-char (point-max)))))
  (let* ((origin (point))
         (line-beginning (line-beginning-position))
         (line-end (line-end-position))
         (left-bound
          (save-excursion
            (skip-chars-backward " \t" line-beginning)
            (point)))
         (right-bound
          (save-excursion
            (skip-chars-forward " \t" line-end)
            (point)))
         (left-text-p (> left-bound line-beginning))
         (right-text-p (< right-bound line-end)))
    (delete-region origin right-bound)
    (when left-text-p
      (delete-region left-bound origin))
    (insert
     (concat (and left-text-p " ") "|>" (and right-text-p " ")))))

(defun jls/inferior-ess-finish-exit-cleanup (buffer)
  "Kill exited iESS BUFFER and delete its terminal-only windows."
  (when (buffer-live-p buffer)
    (when (fboundp #'jls/delete-deletable-buffer-windows)
      (jls/delete-deletable-buffer-windows buffer))
    (kill-buffer buffer)))

(defun jls/inferior-ess-kill-buffer-after-exit (process _message)
  "Arrange to kill the iESS buffer after PROCESS exits."
  (when (memq (process-status process) '(exit signal))
    (let ((buffer (process-buffer process)))
      (when (and (buffer-live-p buffer)
                 (with-current-buffer buffer
                   (derived-mode-p 'inferior-ess-r-mode)))
        (run-at-time 0 nil #'jls/inferior-ess-finish-exit-cleanup
                     buffer)))))

(defun jls/inferior-ess-mouse-focus-input (event)
  "Select the iESS window from EVENT and focus its active input."
  (interactive "e")
  (mouse-set-point event)
  (goto-char (point-max))
  (evil-insert-state))

(defun jls/inferior-ess-return-to-input-on-insert ()
  "Move from iESS scrollback to the active input when entering insert state."
  (when (derived-mode-p 'inferior-ess-r-mode)
    (when-let ((process (get-buffer-process (current-buffer))))
      (when (< (point) (marker-position (process-mark process)))
        (goto-char (point-max))))))

(defun jls/inferior-ess-setup-evil ()
  "Configure Evil state transitions in the current iESS buffer."
  (setq-local comint-prompt-read-only t)
  (evil-define-key
   '(normal insert visual replace operator motion emacs)
   inferior-ess-r-mode-map
   [down-mouse-1]
   #'mouse-drag-region
   [mouse-1]
   #'jls/inferior-ess-mouse-focus-input)
  (evil-define-key
   'insert
   inferior-ess-r-mode-map
   (kbd "RET")
   #'comint-send-input
   (kbd "<return>")
   #'comint-send-input
   (kbd "C-m")
   #'comint-send-input)
  (add-hook 'evil-insert-state-entry-hook
            #'jls/inferior-ess-return-to-input-on-insert
            nil
            t)
  (add-hook 'evil-replace-state-entry-hook
            #'jls/inferior-ess-return-to-input-on-insert
            nil
            t))

(defvar-local jls/inferior-ess-width-update-timer nil
  "Pending deferred console-width update for the current iESS buffer.")

(defun jls/inferior-ess-set-width-from-window (&optional buffer)
  "Set R's console width from the window displaying inferior BUFFER."
  (let* ((buffer (or buffer (current-buffer)))
         (window (get-buffer-window buffer t)))
    (when (and window (process-live-p (get-buffer-process buffer)))
      (with-selected-window window
        (with-current-buffer buffer
          (ess-set-width))))))

(defun jls/inferior-ess-run-width-update (buffer)
  "Update R's console width for BUFFER once its process is idle."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq jls/inferior-ess-width-update-timer nil)
      (when-let ((process (get-buffer-process buffer)))
        (if (process-get process 'busy)
            (jls/inferior-ess-schedule-width-update buffer)
          (jls/inferior-ess-set-width-from-window buffer))))))

(defun jls/inferior-ess-schedule-width-update (buffer)
  "Debounce an R console-width update for iESS BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (when (timerp jls/inferior-ess-width-update-timer)
        (cancel-timer jls/inferior-ess-width-update-timer))
      (setq jls/inferior-ess-width-update-timer
            (run-with-idle-timer
             0.2 nil #'jls/inferior-ess-run-width-update
             buffer)))))

(defun jls/inferior-ess-update-widths-after-resize (frame)
  "Schedule width updates for iESS windows on FRAME after a resize."
  (dolist (window (window-list frame 'no-minibuffer))
    (let ((buffer (window-buffer window)))
      (when (with-current-buffer buffer
              (derived-mode-p 'inferior-ess-r-mode))
        (jls/inferior-ess-schedule-width-update buffer)))))

(defun jls/ess-expression-bounds ()
  "Return the bounds of the complete R expression at point."
  (save-excursion
    ;; ESS treats point on or immediately after a closing delimiter as an
    ;; empty expression boundary.  Move inside the expression first.
    (when (and (not (bobp)) (memq (char-before) '(?\) ?\] ?\})))
      (backward-char))
    (while (and (not (bobp)) (memq (char-after) '(?\) ?\] ?\})))
      (backward-char))
    ;; Expand a token inside a call or assignment to its enclosing top-level R
    ;; expression before collecting continuation lines.
    (ess-climb-to-top-level)
    (ess-continuations-bounds)))

(defun jls/ess-eval-expression (&optional visibly)
  "Evaluate the R expression at point after synchronising the console width.

Include continuation lines belonging to the expression, such as a pipeline or
`ggplot2' layers.  VISIBLY has the same meaning as for `ess-eval-region'."
  (interactive "P")
  (let ((process-buffer (ess-force-buffer-current)))
    (jls/inferior-ess-set-width-from-window process-buffer))
  (if-let ((bounds (jls/ess-expression-bounds)))
      (progn
        (ess-eval-region
         (car bounds) (cadr bounds) visibly "Eval expression")
        (goto-char (cadr bounds))
        (ess-next-code-line))
    (ess-eval-line-and-step visibly)))

(use-package
 ess-r-mode
 :ensure nil
 :mode ("\\.R\\'" . R-mode)
 :hook ((ess-r-mode inferior-ess-r-mode) . electric-pair-local-mode)
 :custom
 ;; Reserve the final text column for Emacs' continuation glyph.
 (ess-auto-width -1)
 ;; In source buffers, let TAB complete when indentation is already correct.
 (ess-tab-complete-in-script t)
 :bind
 (:map
  ess-r-mode-map
  ("s-<return>" . jls/ess-eval-expression)
  ("s-<enter>" . jls/ess-eval-expression))
 :config
 (advice-add #'R :around #'jls/ess-r-use-project-directory)
 (advice-add
  #'ess-process-sentinel
  :after #'jls/inferior-ess-kill-buffer-after-exit)
 (add-hook 'ess-r-mode-hook #'jls/ess-setup-completion)
 (add-hook 'inferior-ess-r-mode-hook #'jls/ess-setup-completion)
 (dolist (map (list ess-r-mode-map inferior-ess-r-mode-map))
   ;; Emacs represents Command-Shift-M as `s-M'.
   (keymap-set map "s-M" #'jls/ess-insert-native-pipe)
   (evil-define-key
    '(normal
      insert visual replace operator motion emacs)
    map (kbd "s-M") #'jls/ess-insert-native-pipe))
 (add-hook
  'ess-r-post-run-hook #'jls/inferior-ess-set-width-from-window)
 (add-hook
  'window-size-change-functions
  #'jls/inferior-ess-update-widths-after-resize)
 (add-to-list
  'display-buffer-alist
  '((major-mode . inferior-ess-r-mode)
    (display-buffer-in-side-window)
    (side . right)
    (window-width . 54))))

(use-package
 corfu
 :ensure nil
 :hook ((ess-r-mode inferior-ess-r-mode) . corfu-mode)
 :custom
 (corfu-auto t)
 (corfu-auto-delay 0.2)
 (corfu-auto-prefix 2)
 (corfu-cycle t)
 (corfu-preselect 'first)
 :bind
 (:map
  corfu-map
  ("RET" . nil)
  ("<return>" . nil)
  ("C-m" . nil)
  ("TAB" . corfu-complete)
  ([tab] . corfu-complete))
 :config
 (require 'corfu-history)
 (corfu-history-mode 1)
 (require 'corfu-popupinfo)
 (corfu-popupinfo-mode 1))

(use-package
 evil-collection
 :ensure nil
 :after evil
 :demand t
 :hook
 ((inferior-ess-r-mode . evil-local-mode)
  (inferior-ess-r-mode . jls/inferior-ess-setup-evil))
 :config
 (evil-collection-init 'comint)
 (evil-set-initial-state 'inferior-ess-r-mode 'insert))

(provide 'jls-editing-r)
;;; jls-editing-r.el ends here
