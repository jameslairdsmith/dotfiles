;;; early-init.el --- Loaded before the GUI/init.el -*- lexical-binding: t; -*-

;;; Commentary:
;; Runs before the first frame is drawn. Disable UI chrome here so it
;; never flashes on screen, and relax GC during startup for speed.

;;; Code:

;; Bump the GC threshold high during startup; we'll lower it later
(setq gc-cons-threshold (* 64 1024 1024))

;; Kill UI chrome before the frame is painted (no flicker).
;;(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)

;;; early-init.el ends here
