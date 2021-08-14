;;; ag-plus.el --- Filtering extensions for ag -*- lexical-binding: t -*-

;; Author: Zachary Romero
;; Maintainer: Zachary Romero
;; Version: 0.1.0
;; Package-Requires: ()
;; Homepage: https://github.com/zkry/ag-plus
;; Keywords: 


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; This package ...

;;; Code:

(defun ag-plus--section-file-name ()
  (string-remove-prefix "File: "
                        (string-trim (thing-at-point 'line t))))

(defun ag-plus--show-all ()
  (let ((inhibit-read-only t))
    (remove-text-properties (point-min)
                            (point-max)
                            '(invisible nil))
    (goto-char (point-min))))

(defun ag-plus--search-in-file-at-section (s)
  "Search for occurrences of S in the file at point.
If no occurrances are found, hide the section.  Return the number of matches found."
  (unless (looking-at "File: ")
    (error "point not a start of section"))
  (let ((inhibit-read-only t)
        (filename (ag-plus--section-file-name)))
    (let ((display)
          (result))
      (with-temp-buffer
        (setq result (call-process "ag" nil t nil "--literal"
                                   "--group" "--line-number" "--column" "--color"
                                   "--color-match" "30\;43" "--color-path" "1\;32"
                                   "--smart-case"
                                   s filename))
        (when (= 0 result)
          (ansi-color-filter-region (point-min) (point-max))
          (setq display (buffer-string))))
      (if (= 0 result)
          (progn
            (end-of-line 1)
            (insert "\n\n---------------------")
            (forward-line -1)
            (insert display)
            (kill-line)
            t)
        (ag-plus--hide-section)
        (forward-line -2)
        nil))))

(defun ag-plus--hide-section ()
  "Hide the section that the cursor is under."
  (let ((inhibit-read-only t))
    (beginning-of-line 1)
    ;; Find the beginning of the section.
    (while (and (not (= 1 (point))) (not (looking-at "File: ")))
      (forward-line -1))
    (when (= 1 (point))
      (error "no section found under point"))
    (let ((start-pos (point)))
      ;; Find the end of the section
      (while (not (looking-at "$"))
        (forward-line 1))
      (forward-line 1)
      (let ((end-pos (point)))
        (kill-region start-pos end-pos))))
  (forward-line 1))

(defun ag-plus--next-section ()
  "Move point to the next section."
  (interactive)
  (forward-line 1)
  (while (and (not (= (point-max) (point))) (not (looking-at "File: ")))
    (forward-line 1))
  (if (= (point-max) (point))
      nil
    t))

(defun ag-plus--filter (contain-regexp)
  "Filter out all sections that don't CONTAIN-REGEXP."
  (goto-char (point-min))
  (while (ag-plus--next-section)
    (let ((filename (ag-plus--section-file-name)))
      (unless (string-match contain-regexp filename)
        (ag-plus--hide-section)
        (forward-line -1)))))

(defun ag-plus--remove (contain-regexp)
  "Filter out all sections that don't CONTAIN-REGEXP."
  (goto-char (point-min))
  (while (ag-plus--next-section)
    (let ((filename (ag-plus--section-file-name)))
      (when (string-match contain-regexp filename)
        (ag-plus--hide-section)
        (forward-line -1)))))

(defun ag-plus--additive-search (search-regexp)
  "For each file in buffer do another serch."
  (goto-char (point-min))
  (let ((found-ct 0))
    (while (ag-plus--next-section)
      (when (ag-plus--search-in-file-at-section search-regexp)
        (setq found-ct (1+ found-ct))))
    (message "Found %d matches." found-ct))
  (goto-char (point-min)))

(defun ag-plus--reset-buffer ()
  (goto-char (point-min))
  (forward-line 3)
  (let ((line (thing-at-point 'line t)))
    (string-match "-- \\(.*\\) \\." line)
    (projectile-ag (match-string 1 line))))

;;; Interactive Commands

(defun ag-plus-refresh ()
  "Refresh the buffer contents by re-running ag command."
  (interactive)
  (ag-plus--reset-buffer))

(defun ag-plus-remove-files (remove-str)
  "Remove all files in the buffer which contain REMOVE-STR."
  (interactive "sFile text to filter out: ")
  (ag-plus--remove remove-str))

(defun ag-plus-filter-files (search-str)
  "Remove all files in the buffer which don't contain SEACH-STR."
  (interactive "sFile text to filter for: ")
  (ag-plus--filter search-str))

(defun ag-plus-additive-search (search-str)
  "Search for SEARCH-STR in each file listed in buffer, showing the results if they exist.

If no results are found the section is hidden from the buffer."
  (interactive "sSearch string:")
  (ag-plus--additive-search search-str))

(defconst ag-plus-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map (kbd "r") 'ag-plus-remove-files)
      (define-key map (kbd "f") 'ag-plus-filter-files)
      (define-key map (kbd "s") 'ag-plus-additive-search))))

(define-minor-mode ag-plus-mode
  "Toggle ag-plus mode.

\\{ag-plus-mode-map}"
  :lighter " ag+"
  :keymap ag-plus-mode-map)


(provide 'ag-plus)

;;; ag-plus.el ends here
