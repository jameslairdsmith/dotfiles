;;; jls-projects.el --- Project workspaces with Tabspaces -*- lexical-binding: t; -*-

;;; Commentary:
;; Give each project its own tab-bar workspace, window configuration and buffer
;; list.  The tab bar itself remains hidden; project workspaces are opened and
;; selected through Consult prompts displayed by Vertico.

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'project)
(require 'recentf)
(require 'seq)

(declare-function consult--buffer-query "consult")
(declare-function consult--buffer-state "consult")
(declare-function consult--buffer-pair "consult" (buffer))
(declare-function consult--file-state "consult")
(declare-function consult--read "consult" (table &rest options))
(declare-function evil-treemacs-state "treemacs-evil" ())
(declare-function jls/remove-buffer-from-window-history
                  "jls-window-management" (window buffer))
(declare-function jls/reset-current-window-buffer-history
                  "jls-window-management")
(declare-function popper--update-popups "popper" ())
(declare-function popper-popup-p "popper" (buffer))
(declare-function popper-select-popup-at-bottom
                  "popper" (buffer &optional alist))
(declare-function projdash-open "projdash" (&optional prompt))
(declare-function tabspaces--buffer-list "tabspaces" (&optional frame tabnum))
(declare-function tabspaces--current-tab-name "tabspaces")
(declare-function tabspaces-clear-buffers "tabspaces")
(declare-function tabspaces-close-workspace "tabspaces")
(declare-function tabspaces--list-tabspaces "tabspaces")
(declare-function tabspaces--local-buffer-p "tabspaces" (buffer))
(declare-function tabspaces-open-or-create-project-and-workspace "tabspaces")
(declare-function treemacs--setup-peek-buffer
                  "treemacs-peek-mode" (path))
(declare-function treemacs--tear-down-peek-mode
                  "treemacs-peek-mode" (&optional restore-window))
(declare-function treemacs-add-and-display-current-project-exclusively
                  "treemacs" ())

(defvar evil-state)
(defvar popper-popup-status)
(defvar recentf-exclude)

(defvar-local jls/popper-origin-window nil
  "Window in which this buffer was manually made into a popup.")

(defvar-local jls/popper-origin-side-action nil
  "Display action which recreates this popup's original side window.")

(recentf-mode 1)

(defvar jls/project-history nil
  "Minibuffer history for project workspace commands.")

(defun jls/current-project-root ()
  "Return the current workspace's project root, or nil.

The current project is determined from the active Tabspaces workspace rather
than from the selected buffer."
  (when-let ((entry
              (rassoc (tabspaces--current-tab-name)
                      tabspaces-project-tab-map)))
    (expand-file-name (car entry))))

(defun jls/consult-project-root (may-prompt)
  "Return the workspace project root for Consult.

Fall back to `project-current', which may prompt when MAY-PROMPT is non-nil."
  (or (jls/current-project-root)
      (when-let ((project (project-current may-prompt)))
        (project-root project))))

(setq consult-project-function #'jls/consult-project-root)

(defun jls/project-file-candidates ()
  "Return current project files with recent files first.

Use fd to include hidden files while respecting ignore files.  Exclude the
Git metadata directory explicitly.  Files absent from `recentf-list' are sorted
alphabetically after the recent files."
  (when-let ((root (jls/consult-project-root nil)))
    (let ((default-directory root)
          (recent-ranks (make-hash-table :test #'equal))
          candidates)
      (cl-loop
       for file in recentf-list
       for rank from 0
       do (puthash (expand-file-name file) rank recent-ranks))
      (setq candidates
            (mapcar
             (lambda (file)
               (cons file (expand-file-name file root)))
             (process-lines
              jls-fd-program
              "--type"
              "file"
              "--hidden"
              "--color=never"
              "--exclude"
              ".git"
              ".")))
      (cl-stable-sort
       candidates
       (lambda (left right)
         (let ((left-rank (gethash (cdr left) recent-ranks))
               (right-rank (gethash (cdr right) recent-ranks)))
           (cond
            ((and left-rank right-rank) (< left-rank right-rank))
            (left-rank t)
            (right-rank nil)
            (t (string-lessp (car left) (car right))))))))))

(defvar jls/consult-source-project-file
  `(:name "Project File"
    :narrow ?f
    :category file
    :face consult-file
    :history file-name-history
    :state ,#'consult--file-state
    :new ,(lambda (_file) (user-error "Select an existing project file"))
    :items ,#'jls/project-file-candidates)
  "Consult source containing every file in the current project.")

(defun jls/consult-project-file ()
  "Choose a project file with recent files listed first."
  (interactive)
  (if-let ((root (jls/consult-project-root nil)))
      (let ((default-directory root)
            (consult-project-function (lambda (_may-prompt) root)))
        (consult-buffer '(jls/consult-source-project-file)))
    (user-error "There is no current project")))

(defun jls/consult-grep-project ()
  "Search the current project with `consult-grep'."
  (interactive)
  (if-let ((root (jls/consult-project-root nil)))
      (let ((default-directory root)
            (consult-project-function (lambda (_may-prompt) root)))
        (consult-grep root))
    (user-error "There is no current project")))

(defun jls/consult-project-buffer ()
  "Switch to a buffer belonging to the current project workspace."
  (interactive)
  (if (jls/current-project-root)
      (consult-buffer '(jls/consult-source-workspace))
    (user-error "The current workspace is not a project")))

;; Temporary local checkout for evaluating Projdash before packaging it with
;; Nix.  Removing this form and restoring `project-dired' below removes the
;; experiment completely.
(use-package
 projdash
 :ensure nil
 :load-path "~/projects/projdash/main"
 :commands projdash-open)

(defun jls/display-popup (buffer &optional alist)
  "Display popup BUFFER according to its type and action ALIST.

Restore manually lowered buffers to their original live window, or recreate
their original side window.  Otherwise, keep Treemacs in a left side window and
use Popper's normal bottom placement for other popup types added later."
  (let ((origin
         (buffer-local-value 'jls/popper-origin-window buffer)))
    (cond
     ((and (window-live-p origin)
           (eq (window-frame origin) (selected-frame)))
      ;; Side windows in this setup remain dedicated while their popup is
      ;; hidden.  Temporarily relax that dedication to restore the popup, then
      ;; put it back so ordinary display actions cannot reuse the window.
      (let ((dedicated (window-dedicated-p origin)))
        (set-window-dedicated-p origin nil)
        (set-window-buffer origin buffer)
        (set-window-dedicated-p origin dedicated))
      (select-window origin)
      origin)
     ((buffer-local-value 'jls/popper-origin-side-action buffer)
      (let ((window
             (display-buffer-in-side-window
              buffer
              (buffer-local-value
               'jls/popper-origin-side-action buffer))))
        (select-window window)
        window))
     ((eq (buffer-local-value 'major-mode buffer) 'treemacs-mode)
      (display-buffer-in-side-window
       buffer
       '((side . left)
         (slot . -1)
         (window-width . 35)
         (dedicated . t))))
     (t (popper-select-popup-at-bottom buffer alist)))))

(defun jls/popper-toggle-type-in-place (&optional buffer)
  "Toggle BUFFER's Popper status without moving its window.

Use the current buffer when BUFFER is nil.  Its existing position is retained
while its status changes.  Remember its window and, for side windows, the
placement needed to recreate it after Popper deletes it."
  (interactive)
  (let* ((buffer (get-buffer (or buffer (current-buffer))))
         (status (buffer-local-value 'popper-popup-status buffer))
         (origin
          (if (eq (window-buffer (selected-window)) buffer)
              (selected-window)
            (get-buffer-window buffer)))
         (side (and origin (window-parameter origin 'window-side)))
         (side-action
          (when side
            (append
             `((side . ,side)
               (slot . ,(window-parameter origin 'window-slot)))
             (if (memq side '(left right))
                 `((window-width . ,(window-total-width origin)))
               `((window-height . ,(window-total-height origin))))
             (when-let ((dedicated (window-dedicated-p origin)))
               `((dedicated . ,dedicated)))))))
    (with-current-buffer buffer
      (if (memq status '(popup user-popup))
          (progn
            (setq popper-popup-status
                  (and (popper-popup-p buffer) 'raised)
                  jls/popper-origin-window nil
                  jls/popper-origin-side-action nil)
            (setq mode-line-format (default-value 'mode-line-format)))
        (setq popper-popup-status
              (if (popper-popup-p buffer) 'popup 'user-popup)
              jls/popper-origin-window origin
              jls/popper-origin-side-action side-action)))
    (popper--update-popups)
    (force-mode-line-update t)))

(use-package
 popper
 :ensure nil
 :demand t
 :bind
 (("C-`" . popper-toggle)
  ("M-`" . popper-cycle)
  ("C-M-`" . jls/popper-toggle-type-in-place))
 :custom
 (popper-display-function #'jls/display-popup)
 (popper-reference-buffers '(treemacs-mode))
 :config
 ;; Remove the earlier origin-preserving advice when reloading this module in
 ;; an existing Emacs session.  Popper should now delete every popup window.
 (advice-remove
  'popper--delete-popup 'jls/popper-preserve-origin-window)
 (popper-mode 1))

(defun jls/hidden-popper-buffer-p (buffer)
  "Return non-nil when BUFFER is a hidden Popper popup."
  (let ((status (buffer-local-value 'popper-popup-status buffer)))
    (and (not (get-buffer-window buffer t))
         (not (eq status 'raised))
         (or (memq status '(popup user-popup suppressed))
             (popper-popup-p buffer)))))

(defun jls/consult-popup-state ()
  "Return a Consult state function which previews via Popper.

Each preview starts from the window configuration which preceded the Consult
session.  Cancelling therefore restores the original layout; accepting a
candidate restores it first and then displays the chosen buffer using Popper's
normal display machinery."
  (let (original-configuration original-window)
    (lambda (action candidate)
      (pcase action
        ('setup
         (setq original-configuration (current-window-configuration)
               original-window (selected-window)))
        ((or 'preview 'exit)
         (when original-configuration
           (set-window-configuration original-configuration))
         (when-let* (((eq action 'preview))
                     (buffer (and candidate (get-buffer candidate)))
                     (window (display-buffer buffer)))
           ;; `jls/display-popup' selects its window.  Keep keyboard focus in
           ;; the originating window while the Posframe prompt remains active.
           (when (window-live-p original-window)
             (select-window original-window 'norecord))))
        ('return
         (when original-configuration
           (set-window-configuration original-configuration))
         (when-let* ((buffer (and candidate (get-buffer candidate)))
                     (window (display-buffer buffer)))
           (select-window window)))))))

(defun jls/consult-popup ()
  "Choose a hidden Popper buffer and display it as a popup."
  (interactive)
  (let ((candidates
         (mapcar
          #'consult--buffer-pair
          (seq-filter #'jls/hidden-popper-buffer-p (buffer-list)))))
    (unless candidates
      (user-error "There are no hidden Popper buffers"))
    (consult--read
     candidates
     :prompt "Popup: "
     :category 'buffer
     :require-match t
     :history 'buffer-name-history
     :sort nil
     :state (jls/consult-popup-state)
     :preview-key '(:debounce 0.1 any))))

(defun jls/treemacs-use-single-preview-tab (function path)
  "Call Treemacs peek FUNCTION for PATH using one changing tab-line tab.

Do not register files opened only for previewing with Recentf."
  (let* ((recentf-exclude
          (cons
           (format "\\`%s\\'" (regexp-quote (expand-file-name path)))
           (and (boundp 'recentf-exclude) recentf-exclude)))
         (file-buffer (get-file-buffer path))
         (preview-window
          (or (and file-buffer (get-buffer-window file-buffer))
              (next-window (selected-window))))
         (previous-previews
          (cl-loop
           for window in (window-list)
           for buffer =
           (window-parameter window 'jls/treemacs-preview-buffer)
           when buffer collect (cons window buffer))))
    (prog1 (funcall function path)
      ;; Directory previews use Dired buffers, which `get-file-buffer' cannot
      ;; find because they do not set `buffer-file-name'.  Read the buffer from
      ;; the window Treemacs selected for the preview instead.
      (let ((buffer (and (window-live-p preview-window)
                         (window-buffer preview-window))))
        (dolist (preview previous-previews)
          (unless (eq (cdr preview) buffer)
            (jls/remove-buffer-from-window-history
             (car preview) (cdr preview))
            (set-window-parameter
             (car preview) 'jls/treemacs-preview-buffer nil)))
        (when buffer
          (set-window-parameter
           preview-window 'jls/treemacs-preview-buffer buffer))))))

(defun jls/treemacs-clear-preview-tab-tracking (&rest _arguments)
  "Forget the tab-line preview buffer tracked in each live window."
  (dolist (window (window-list))
    (set-window-parameter window 'jls/treemacs-preview-buffer nil)))

(use-package
 treemacs
 :ensure nil
 :commands treemacs-add-and-display-current-project-exclusively
 :custom
 (treemacs-position 'left)
 (treemacs-width-is-initially-locked nil)
 :config
 (with-eval-after-load 'treemacs-peek-mode
   (advice-add
    #'treemacs--setup-peek-buffer
    :around #'jls/treemacs-use-single-preview-tab)
   (advice-add
    #'treemacs--tear-down-peek-mode
    :after #'jls/treemacs-clear-preview-tab-tracking)))

(use-package
 treemacs-tab-bar
 :ensure nil
 :after treemacs
 :config (treemacs-set-scope-type 'Tabs))

(defun jls/treemacs-restore-evil-state-on-selection (frame)
  "Restore Treemacs Evil state when FRAME selects a Treemacs window."
  (when-let* ((window (frame-selected-window frame))
              ((window-live-p window))
              (buffer (window-buffer window)))
    (with-current-buffer buffer
      (when (and (derived-mode-p 'treemacs-mode)
                 (not (eq evil-state 'treemacs)))
        (evil-treemacs-state)))))

(use-package
 treemacs-evil
 :ensure nil
 :after (evil treemacs)
 :config
 ;; Match the section-toggle binding used in Magit and other special buffers.
 (keymap-set evil-treemacs-state-map "z" #'treemacs-TAB-action)
 ;; Treemacs Evil restores its state after mouse clicks, but not after every
 ;; other way of selecting its window.  Cover all window-selection methods.
 (add-hook
  'window-selection-change-functions
  #'jls/treemacs-restore-evil-state-on-selection))

(use-package
 treemacs-magit
 :ensure nil
 :after (magit treemacs))

(use-package
 treemacs-nerd-icons
 :ensure nil
 :after treemacs
 :custom
 ;; nerd-icons defaults to Symbols Nerd Font Mono.  Use the Nerd Font already
 ;; installed by the system configuration instead.
 (nerd-icons-font-family "JetBrainsMono Nerd Font Mono")
 :config (treemacs-nerd-icons-config))

(defun jls/open-project-dashboard ()
  "Open Projdash with the current project in Treemacs on its left."
  (interactive)
  ;; `project-switch-project' exposes the chosen project through a buffer-local
  ;; `project-current-directory-override' while invoking this command.  Resolve
  ;; it before Projdash changes buffers and loses that override.
  (let ((project-root (project-root (project-current t))))
    (projdash-open)
    ;; Treemacs selects its own side window while opening.  Leave Projdash
    ;; selected so subsequent project setup applies to the main window.
    (save-selected-window
      (let ((default-directory project-root))
        (treemacs-add-and-display-current-project-exclusively)))))

(defun jls/open-project ()
  "Open a known project in a new Tabspaces workspace.

Projects which already have an open workspace are omitted from the prompt.
The candidates come from project.el and are selected with Consult and Vertico.
Refresh projects immediately below ~/projects before displaying the prompt."
  (interactive)
  (let ((projects-directory (expand-file-name "~/projects")))
    (when (file-directory-p projects-directory)
      (let ((inhibit-message t))
        (project-remember-projects-under projects-directory))))
  (let* ((tabs (tabspaces--list-tabspaces))
         (open-projects
          (mapcar
           (lambda (entry) (expand-file-name (car entry)))
           (seq-filter
            (lambda (entry) (member (cdr entry) tabs))
            tabspaces-project-tab-map)))
         (projects
          (seq-remove
           (lambda (project)
             (member (expand-file-name project) open-projects))
           (project-known-project-roots))))
    (unless projects
      (user-error "There are no unopened known projects"))
    (tabspaces-open-or-create-project-and-workspace
     (consult--read
      projects
      :prompt "Open project: "
      :category 'project
      :history 'jls/project-history
      :require-match t
      :sort nil))
    ;; Tabspaces creates the workspace through *scratch*, while tab-bar copies
    ;; the selected window's buffer history from the previous workspace.  Once
    ;; Projdash and Treemacs are open, discard both kinds of transitional state.
    (tabspaces-clear-buffers)
    (jls/reset-current-window-buffer-history)))

(defun jls/project-unique-buffers ()
  "Return live buffers belonging only to the current Tabspaces workspace."
  (let* ((current-tab-name (tabspaces--current-tab-name))
         (current-buffers (tabspaces--buffer-list))
         (other-buffers
          (cl-loop
           for tab in (tab-bar-tabs)
           for tab-index from 0
           unless (equal (alist-get 'name tab) current-tab-name)
           append (tabspaces--buffer-list nil tab-index))))
    (seq-remove
     (lambda (buffer) (memq buffer other-buffers))
     current-buffers)))

(defun jls/close-project ()
  "Kill the current project's unique buffers and close its workspace.

Buffers which also belong to another Tabspaces workspace remain alive.  Honour
Tabspaces' included and excluded buffer lists in the same way as its standard
kill-and-close command."
  (interactive)
  (unless (jls/current-project-root)
    (user-error "The current workspace is not a project"))
  (let ((buffers (jls/project-unique-buffers)))
    (unwind-protect
        (dolist (buffer buffers)
          (let ((name (buffer-name buffer)))
            (unless (or (member name tabspaces-exclude-buffers)
                        (member name tabspaces-include-buffers))
              (kill-buffer buffer))))
      (tabspaces-close-workspace))))

(defun jls/switch-project ()
  "Switch to an open project or the default workspace with Consult and Vertico."
  (interactive)
  (let* ((tabs (tabspaces--list-tabspaces))
         (workspaces
          (seq-filter
           (lambda (tab)
             (and (member tab tabs)
                  (not (equal tab (tabspaces--current-tab-name)))))
           (delete-dups
            (cons
             tabspaces-default-tab
             (mapcar #'cdr tabspaces-project-tab-map))))))
    (unless workspaces
      (user-error "There are no other open workspaces"))
    (tab-bar-switch-to-tab
     (consult--read
      workspaces
      :prompt "Switch workspace: "
      :category 'project
      :history 'jls/project-history
      :require-match t
      :sort nil))))

(use-package
 tabspaces
 :ensure nil
 :demand t
 :custom
 (tabspaces-default-tab "*none*")
 (tabspaces-include-buffers nil)
 (tabspaces-keymap-prefix nil)
 (tabspaces-project-switch-commands #'jls/open-project-dashboard)
 (tabspaces-session nil)
 (tabspaces-session-auto-restore nil)
 (tabspaces-use-filtered-buffers-as-default t)
 :init
 ;; Tabspaces uses tab-bar tabs as workspace objects, but they do not need to
 ;; occupy a line in the interface.
 (setq tab-bar-show nil)
 :config
 (tab-bar-mode 1)
 (tab-bar-rename-tab tabspaces-default-tab)
 (tabspaces-mode 1))

;; Make the default Consult buffer source workspace-local.  All buffers remain
;; available by narrowing to Consult's hidden `b' source.
(with-eval-after-load 'consult
  (plist-put consult-source-buffer :hidden t)
  (plist-put consult-source-buffer :default nil)
  (defvar jls/consult-source-workspace
    (list
     :name "Workspace Buffers"
     :narrow ?w
     :history 'buffer-name-history
     :category 'buffer
     :state #'consult--buffer-state
     :default t
     :items
     (lambda ()
       (consult--buffer-query
        :predicate #'tabspaces--local-buffer-p
        :sort 'visibility
        :as #'buffer-name)))
    "Consult source containing buffers in the current workspace.")
  (add-to-list 'consult-buffer-sources 'jls/consult-source-workspace))

(defvar-keymap jls/project-map
  "/"
  #'jls/consult-grep-project
  "o"
  #'jls/open-project
  "s"
  #'jls/switch-project
  "x"
  #'jls/close-project)

(provide 'jls-projects)
;;; jls-projects.el ends here
