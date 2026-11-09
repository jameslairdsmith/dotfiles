;;; jls-formatting.el --- General formatting commands -*- lexical-binding: t; -*-

;;; Commentary:
;; Provide commands for formatting buffers with treefmt.

;;; Code:

(require 'subr-x)

(defvar jls-treefmt-program "treefmt"
  "Path to the treefmt executable.")

(defun jls/treefmt-buffer ()
  "Format the current file-visiting buffer with treefmt.
Use treefmt's standard-input mode so unsaved buffer contents are formatted
without first writing them to disk.  The visited file name tells treefmt which
configured formatter to use."
  (interactive)
  (unless buffer-file-name
    (user-error "The current buffer is not visiting a file"))
  (let ((output-buffer (generate-new-buffer " *treefmt output*"))
        (stderr-file (make-temp-file "treefmt-stderr-")))
    (unwind-protect
        (let ((status
               (call-process-region
                (point-min)
                (point-max)
                jls-treefmt-program
                nil
                (list output-buffer stderr-file)
                nil
                "--stdin"
                (expand-file-name buffer-file-name))))
          (if (zerop status)
              (progn
                (replace-buffer-contents output-buffer)
                (message "Formatted %s with treefmt" buffer-file-name))
            (let ((diagnostic
                   (string-trim
                    (with-temp-buffer
                      (insert-file-contents stderr-file)
                      (buffer-string)))))
              (user-error
               "treefmt failed%s"
               (if (string-empty-p diagnostic)
                   ""
                 (concat ": " diagnostic))))))
      (kill-buffer output-buffer)
      (delete-file stderr-file))))

(provide 'jls-formatting)
;;; jls-formatting.el ends here
