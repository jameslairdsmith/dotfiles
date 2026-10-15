;;; jls-terminal-emulators.el --- Terminal emulators -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal emulators used from full editor sessions.

;;; Code:

(use-package
 vterm
 :ensure nil
 :commands vterm
 :config (setq vterm-timer-delay nil))

(use-package
 eat
 :ensure nil
 :commands (eat eat-project)
 :custom
 (eat-minimum-latency 0.008)
 (eat-minimum-latency 0.033))

(provide 'jls-terminal-emulators)
;;; jls-terminal-emulators.el ends here
