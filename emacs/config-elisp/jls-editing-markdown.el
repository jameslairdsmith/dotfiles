;;; jls-editing-markdown.el --- Markdown editing configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Use Markdown mode for Markdown, R Markdown, and Quarto documents.

;;; Code:

(use-package
 markdown-mode
 :ensure nil
 :mode
 (("\\.md\\'" . markdown-mode)
  ("\\.[RrQq]md\\'" . markdown-mode)))

(provide 'jls-editing-markdown)
;;; jls-editing-markdown.el ends here
