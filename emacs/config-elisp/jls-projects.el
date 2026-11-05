;;; jls-projects.el --- Project workspaces with Tabspaces -*- lexical-binding: t; -*-

;;; Commentary:
;; Give each project its own tab-bar workspace, window configuration and buffer
;; list.  The tab bar itself remains hidden; project workspaces are opened and
;; selected through Consult prompts displayed by Vertico.

;;; Code:

(require 'consult)
(require 'project)
(require 'seq)

(declare-function consult--buffer-query "consult")
(declare-function consult--buffer-state "consult")
(declare-function consult--read "consult")
(declare-function jls/reset-current-window-buffer-history
                  "jls-window-management")
(declare-function tabspaces--current-tab-name "tabspaces")
(declare-function tabspaces-clear-buffers "tabspaces")
(declare-function tabspaces--list-tabspaces "tabspaces")
(declare-function tabspaces--local-buffer-p "tabspaces" (buffer))
(declare-function tabspaces-open-or-create-project-and-workspace "tabspaces")

(defvar jls/project-history nil
  "Minibuffer history for project workspace commands.")

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
    ;; Dired is open, discard both kinds of transitional state.
    (tabspaces-clear-buffers)
    (jls/reset-current-window-buffer-history)))

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
 (tabspaces-project-switch-commands #'project-dired)
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
  #'jls/switch-project)

(provide 'jls-projects)
;;; jls-projects.el ends here
