;; Basic display options
(setq inhibit-startup-message t)
;;(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing 
;; (menu-bar-mode -1)            ; Disable the menu bar
(setq visible-bell t)

(set-face-attribute 'default nil :font "Fira Code" :height 120 :family "Bold")


;; Basic keybindings
(global-set-key (kbd "<C-return>") 'eval-defun)
(global-set-key (kbd "C-S-<return>") 'eval-buffer)
(global-set-key (kbd "s-S-<return>") 'eval-buffer)
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "s-<return>") 'eval-defun)
;;(global-set-key (kbd "C-c") 'ns-copy-including-secondary)  ;; Like copy
(global-set-key (kbd "s-c") 'ns-copy-including-secondary) 
;;(global-set-key (kbd "C-v") 'yank)
(global-set-key (kbd "s-v") 'yank) ;; Paste
;;(global-set-key (kbd "C-x") 'kill-region)
(global-set-key (kbd "s-x") 'kill-region) 
;;(global-set-key (kbd "C-2") 'execute-extended-command)
;;(global-set-key (kbd "s-2") 'execute-extended-command)
(global-set-key (kbd "s-p") 'execute-extended-command)
; Basically a command palette
(global-set-key (kbd "s-s") 'save-buffer)
;;(global-set-key (kbd "C-s") 'save-buffer)
(global-set-key (kbd "s-f") 'find-file)

;; Package stuff
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))
(unless (package-installed-p 'use-package)
   (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Display settings
(column-number-mode)
(global-display-line-numbers-mode t)

(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package all-the-icons)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))
;;(setq doom-modeline-height 15)

(use-package doom-themes
  :init (load-theme 'doom-gruvbox t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Emacs tooling

(use-package ivy
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)	
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :config (ivy-mode 1))

(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :ensure t
  :init (counsel-mode 1))

(use-package counsel
  :bind (("s-p" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("s-f" . counsel-find-file)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history)))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))



;; Fun with changing themes
(load-theme 'doom-dracula t)
(load-theme 'doom-earl-grey t)
(load-theme 'doom-material t)

;; Just for editing
(find-file "/Users/jameslaird-smith/.emacs.d/wip-init.el")
(split-window-horizontally)
(find-file "/Users/jameslaird-smith/.emacs.d/init.el")

(toggle-frame-fullscreen)
;(toggle-frame-maximized)
