;;; jls-projects.el --- Project workspaces with Tabspaces -*- lexical-binding: t; -*-

;;; Commentary:
;; Give each project its own tab-bar workspace, window configuration and buffer
;; list.  The tab bar itself remains hidden; project workspaces are opened and
;; selected through Consult prompts displayed by Vertico.

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'project)
(require 'seq)

(declare-function consult--buffer-query "consult")
(declare-function consult--buffer-state "consult")
(declare-function consult--read "consult")
(declare-function jls/remove-buffer-from-window-history
                  "jls-window-management" (window buffer))
(declare-function jls/reset-current-window-buffer-history
                  "jls-window-management")
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

(defvar recentf-exclude)

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

(defun jls/consult-project-file ()
  "Find a file recursively in the current project with `consult-fd'."
  (interactive)
  (if-let ((root (jls/consult-project-root nil)))
      (consult-fd root)
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

Keep Treemacs in a left side window; use Popper's normal bottom placement for
other popup types that may be added later."
  (if (eq (buffer-local-value 'major-mode buffer) 'treemacs-mode)
      (display-buffer-in-side-window
       buffer
       '((side . left)
         (slot . -1)
         (window-width . 35)
         (dedicated . t)))
    (popper-select-popup-at-bottom buffer alist)))

(use-package
 popper
 :ensure nil
 :demand t
 :bind
 (("C-`" . popper-toggle)
  ("M-`" . popper-cycle)
  ("C-M-`" . popper-toggle-type))
 :custom
 (popper-display-function #'jls/display-popup)
 (popper-reference-buffers '(treemacs-mode))
 :config (popper-mode 1))

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
 :custom (treemacs-position 'left)
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

(use-package
 treemacs-evil
 :ensure nil
 :after (evil treemacs)
 :config
 ;; Match the section-toggle binding used in Magit and other special buffers.
 (keymap-set evil-treemacs-state-map "z" #'treemacs-TAB-action))

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
The candidates come from project.el and are selected with Consult and Vertico."
  (interactive)
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
  "o"
  #'jls/open-project
  "s"
  #'jls/switch-project
  "x"
  #'jls/close-project)

(provide 'jls-projects)
;;; jls-projects.el ends here
