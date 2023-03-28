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
;(global-set-key (kbd "<C-return>") 'eval-defun)
;(global-set-key (kbd "C-S-<return>") 'eval-buffer)
;(global-set-key (kbd "s-S-<return>") 'eval-buffer)
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

(global-set-key (kbd "s-b") 'counsel-switch-buffer)

;; Maybe use helpful?

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))


(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

;; For some reason these remaps don't affect the global describe functions?

(define-key emacs-lisp-mode-map (kbd "s-t") 'counsel-load-theme)

(defun open-init-el ()
  "Opens init.el file"
  (interactive)
    (find-file "~/.emacs.d/init.el"))

;; Custom keybindings 

;; General
 
(general-define-key (kbd "s-t") 'counsel-load-theme)

(use-package general
  :config
  (general-create-definer rune/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "s-SPC")

  (rune/leader-keys
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")))


;;(use-package evil
  ;;:init
  ;;(setq evil-want-integration t)
  ;;(setq evil-want-keybinding nil) ; The alternative is to use evil-collection
  ;;(setq evil-want-C-u-scroll t)
  ;;(setq evil-want-C-i-jump nil)
  ;;:config
  ;;(evil-mode 1)
  ;;(define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state) ; Go back to normal mode
  ;;(define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
;;
  ;; Use visual line motions even outside of visual-line-mode buffers
  ;;(evil-global-set-key 'motion "j" 'evil-next-visual-line)
  ;;(evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  ;;(evil-set-initial-state 'messages-buffer-mode 'normal)
  ;;(evil-set-initial-state 'dashboard-mode 'normal))

;;(use-package evil-collection
  ;;:after evil
  ;;:config
  ;;(evil-collection-init))


;; Fun with changing themes
(load-theme 'doom-gruvbox t)
(load-theme 'doom-dracula t)
(load-theme 'doom-earl-grey t)
(load-theme 'doom-material t)

;; Just for editing
;; (find-file "/Users/jameslaird-smith/.emacs.d/wip-init.el")
;; (split-window-horizontally)
;; (find-file "/Users/jameslaird-smith/.emacs.d/init.el")

;;(ess-r-mode)
;; (R)

(setq ess-eval-visibly 'nowait)

(setq ess-R-font-lock-keywords
      '((ess-R-fl-keyword:keywords . t)
	(ess-R-fl-keyword:constants . t)
	(ess-R-fl-keyword:modifiers . t)
	(ess-R-fl-keyword:fun-defs . t)
	(ess-R-fl-keyword:assign-ops . t)
	(ess-R-fl-keyword:%op% . t)
	(ess-fl-keyword:fun-calls . t)
	(ess-fl-keyword:numbers . t)
	(ess-fl-keyword:operators)
	(ess-fl-keyword:delimiters)
	(ess-fl-keyword:=)
	(ess-R-fl-keyword:F&T . t)))

(show-paren-mode)
(setq ess-use-flymake nil)

(use-package flycheck
  :ensure t
  :init
  (global-flycheck-mode t))

(add-hook 'ess-r-mode-hook
	  '(lambda ()
	     (local-set-key (kbd "C-9") #'ess-rdired)))
;; Close Rdired buffer with F9 as well:
(add-hook 'ess-rdired-mode-hook
	  '(lambda ()
	     (local-set-key (kbd "C-9") #'kill-buffer-and-window)))

(setq display-buffer-alist
      '(("*R Dired"
	 (display-buffer-reuse-window display-buffer-at-bottom)
	 (window-width . 0.5)
	 (window-height . 0.25)
	 (reusable-frames . nil))
	("*R"
	 (display-buffer-reuse-window display-buffer-in-side-window)
	 (side . right)
	 (slot . -1)
	 (window-width . 0.5)
	 (reusable-frames . nil))
	("*Help"
	 (display-buffer-reuse-window display-buffer-in-side-window)
	 (side . right)
	 (slot . 1)
	 (window-width . 0.5)
	 (reusable-frames . nil))))

(use-package company
  :ensure t
  :config
  ;; Turn on company-mode globally:
  (add-hook 'after-init-hook 'global-company-mode)
  ;; Only activate company in R scripts, not in R console:
  (setq ess-use-company 'script-only))

(add-hook 'ess-r-mode-hook
	  '(lambda ()
	     (local-set-key (kbd "C-8") #'company-R-args)))

(setq company-selection-wrap-around t
      ;; Align annotations to the right tooltip border:
      company-tooltip-align-annotations t
      ;; Idle delay in seconds until completion starts automatically:
      company-idle-delay 0.45
      ;; Completion will start after typing two letters:
      company-minimum-prefix-length 2
      ;; Maximum number of candidates in the tooltip:
      company-tooltip-limit 10)

(use-package company-quickhelp
  :ensure t
  :config
  ;; Load company-quickhelp globally:
  (company-quickhelp-mode)
  ;; Time before display of documentation popup:
  (setq company-quickhelp-delay 0.3))


(toggle-frame-fullscreen)
;(toggle-frame-maximized)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("2721b06afaf1769ef63f942bf3e977f208f517b187f2526f0e57c1bd4a000350" default))
 '(package-selected-packages
   '(key-quiz mugur eval-in-repl eval-sexp-fu ess which-key use-package rainbow-delimiters ivy-rich hydra helpful general evil-collection doom-themes doom-modeline counsel command-log-mode all-the-icons)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
