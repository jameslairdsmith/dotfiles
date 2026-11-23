;;; jls-pdf.el --- PDF reading configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Read PDF documents with pdf-tools and its Evil integration.

;;; Code:

(defun jls/pdf-retarget-page-overlay (window)
  "Attach the PDF page overlay to the WINDOW now displaying its buffer.
The tab and buffer movement commands can show a PDF in a different window
while `image-mode' retains the overlay's previous window restriction."
  (when (and (window-live-p window)
             (with-current-buffer (window-buffer window)
               (derived-mode-p 'pdf-view-mode)))
    (with-current-buffer (window-buffer window)
      (when-let* ((winprops (image-mode-winprops window))
                  (overlay (cdr (assq 'overlay winprops))))
        (overlay-put overlay 'window window)))))

(defun jls/pdf-track-display-window ()
  "Keep the current PDF's rendered page attached to its display window."
  (add-hook
   'window-buffer-change-functions
   #'jls/pdf-retarget-page-overlay
   nil
   t))

(use-package
 pdf-tools
 :ensure nil
 :mode ("\\.pdf\\'" . pdf-view-mode)
 :hook
 ((pdf-view-mode . evil-local-mode)
  (pdf-view-mode . jls/pdf-track-display-window))
 :init (setq-default pdf-view-display-size 'fit-width)
 :config
 ;; Nix supplies the native epdfinfo server; only activate the Emacs modes.
 ;; Load their definitions explicitly because Nix does not use package.el's
 ;; generated package autoloads.
 (mapc
  #'require
  '(pdf-annot
    pdf-cache
    pdf-history
    pdf-isearch
    pdf-links
    pdf-misc
    pdf-occur
    pdf-outline
    pdf-sync))
 (pdf-tools-install-noverify)
 (with-eval-after-load 'evil-collection
   (evil-collection-init '((pdf pdf-view)))))

(provide 'jls-pdf)
;;; jls-pdf.el ends here
