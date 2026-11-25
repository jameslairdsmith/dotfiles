;;; jls-editing-r-inline-results.el --- Inline R results -*- lexical-binding: t; -*-

;;; Commentary:
;; Evaluate a complete R expression through ESS and insert its textual output
;; below the expression as conventional `#>' comments.

;;; Code:

(require 'ansi-color)
(require 'jls-editing-r)

(defun jls/ess-inline-results--r-string (string)
  "Return STRING quoted as an R character literal."
  (concat
   "\""
   (replace-regexp-in-string "[\\\"\n\r\t]"
                             (lambda (match)
                               (pcase match
                                 ("\\" "\\\\")
                                 ("\"" "\\\"")
                                 ("\n" "\\n")
                                 ("\r" "\\r")
                                 ("\t" "\\t")))
                             string
                             t t)
   "\""))

(defun jls/ess-inline-results--command (code)
  "Build an R command that evaluates CODE globally and prints its value."
  (format
   (concat
    "local({tryCatch({.jls_result <- withVisible(eval(parse(text=%s, "
    "keep.source=TRUE), envir=.GlobalEnv)); "
    "if (.jls_result$visible) print(.jls_result$value)}, "
    "error=function(.jls_error) cat('Error: ', "
    "conditionMessage(.jls_error), '\\n', sep=''))})\n")
   (jls/ess-inline-results--r-string code)))

(defun jls/ess-inline-results--output-string (buffer)
  "Return cleaned R output captured in BUFFER."
  (with-current-buffer buffer
    (let ((output
           (ansi-color-filter-apply
            (buffer-substring-no-properties
             (point-min) (point-max)))))
      (setq output (string-replace "\r" "" output))
      (string-trim-right output))))

(defun jls/ess-inline-results--comment-output (output indentation)
  "Turn OUTPUT into R comments prefixed by INDENTATION and `#>'."
  (mapconcat (lambda (line)
               (concat
                indentation "#>"
                (unless (string-empty-p line)
                  " ")
                line))
             (split-string output "\n" nil)
             "\n"))

(defun jls/ess-inline-results--replace (bounds output)
  "Replace the inline result after BOUNDS with cleaned R OUTPUT.

Contiguous `#>' comment lines immediately following the expression are treated
as the previous result.  Move point to the next R expression afterwards."
  (let ((indentation
         (save-excursion
           (goto-char (car bounds))
           (buffer-substring-no-properties
            (line-beginning-position)
            (progn
              (back-to-indentation)
              (point))))))
    (atomic-change-group
      (goto-char (cadr bounds))
      (end-of-line)
      ;; Ensure there is a line on which to find or insert the result.
      (if (eobp)
          (insert "\n")
        (forward-char))
      (let ((result-start (point)))
        (while (looking-at
                (rx line-start (* blank) "#>" (* nonl) line-end))
          (forward-line))
        (delete-region result-start (point))
        (goto-char result-start)
        (unless (string-empty-p output)
          (insert
           (jls/ess-inline-results--comment-output
            output indentation)
           "\n"))))
    (goto-char (cadr bounds))
    (ess-next-code-line)))

(defun jls/ess-eval-expression-inline ()
  "Evaluate the R expression at point and insert its output as comments.

Use the current ESS R process.  Replace an immediately adjacent block of `#>'
comments from a previous invocation, then advance to the next expression."
  (interactive)
  (unless (derived-mode-p 'ess-r-mode)
    (user-error
     "Inline R results are only available in R source buffers"))
  (let ((bounds (jls/ess-expression-bounds)))
    (unless bounds
      (user-error "No R expression at point"))
    (let* ((code
            (buffer-substring-no-properties
             (car bounds) (cadr bounds)))
           (process-buffer (ess-force-buffer-current))
           (process (get-buffer-process process-buffer))
           (output-buffer
            (generate-new-buffer " *jls-ess-inline-output*")))
      (jls/inferior-ess-set-width-from-window process-buffer)
      (unwind-protect
          (progn
            (ess-command
             (jls/ess-inline-results--command code)
             output-buffer
             nil
             nil
             nil
             process)
            (jls/ess-inline-results--replace
             bounds
             (jls/ess-inline-results--output-string output-buffer)))
        (when (buffer-live-p output-buffer)
          (kill-buffer output-buffer))))))

(with-eval-after-load 'ess-r-mode
  (dolist (key '("s-S-<return>" "s-S-<enter>"))
    (define-key
     ess-r-mode-map (kbd key) #'jls/ess-eval-expression-inline)
    (evil-define-key
     '(normal insert visual replace operator motion emacs)
     ess-r-mode-map
     (kbd key)
     #'jls/ess-eval-expression-inline)))

(provide 'jls-editing-r-inline-results)
;;; jls-editing-r-inline-results.el ends here
