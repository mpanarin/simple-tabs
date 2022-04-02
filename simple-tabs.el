;; -*- mode: emacs-lisp; lexical-binding: t -*-
;; TODO: tabs should never jump. I should probably cache their position.
;; TODO: Allow passing optional buffer to keep for `simple-tabs--close-other'

(require 'helm)
(require 'dash)
(require 'tab-line)
(require 'projectile)


;; Customization

(defgroup simple-tabs nil
  "Show simple tabs in Emacs using tab-line-mode."
  :group 'tools)

(defcustom simple-tabs-excluded-buffers-regexp '()
  "Regexps of buffers to never show in simple-tabs."
  :type '(repeat string)
  :group 'simple-tabs)

(defcustom simple-tabs-disabled-in-buffers-regexp '()
  "Regex for buffer names to disable simple-tabs in."
  :type '(repeat string)
  :group 'simple-tabs)

(defcustom simple-tabs-disabled-in-modes '()
  "Major-modes to disable simple-tabs in."
  :type '(repeat symbol)
  :group 'simple-tabs)

(defcustom simple-tabs-keymap-prefix (kbd "C-c C-t")
  "Simple-tabs keymap prefix."
  :type 'string
  :group 'simple-tabs)


;; Functions

(defun simple-tabs--switch (DIRECTION)
  "Switch tab in a specific DIRECTION.
DIRECTION can be 'left 'right"
  (let* ((tabs (funcall tab-line-tabs-function))
         (buffer (current-buffer))
         (index (-elem-index buffer tabs))
         (switch-to (pcase DIRECTION
                      ('left (nth (- index 1) tabs))
                      ('right (nth (+ index 1) tabs)))))
    (if switch-to
        (switch-to-buffer switch-to t t))))

(defun simple-tabs--switch-left ()
  "Switch tab to the one in the left"
  (interactive)
  (simple-tabs--switch 'left))

(defun simple-tabs--switch-right ()
  "Switch tab to the one in the right"
  (interactive)
  (simple-tabs--switch 'right))

(defun simple-tabs--select-by-num (INDEX)
  "select tab by index.
if INDEX out of range - do nothing."
  (let* ((tabs (funcall tab-line-tabs-function))
         (switch-to (nth (- INDEX 1) tabs)))
    (if switch-to
        (switch-to-buffer switch-to t t))))

(defun simple-tabs--select-1 ()
  "Select tab by index 1 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 1))

(defun simple-tabs--select-2 ()
  "Select tab by index 2 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 2))

(defun simple-tabs--select-3 ()
  "Select tab by index 3 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 3))

(defun simple-tabs--select-4 ()
  "Select tab by index 4 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 4))

(defun simple-tabs--select-5 ()
  "Select tab by index 5 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 5))

(defun simple-tabs--select-6 ()
  "Select tab by index 6 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 6))

(defun simple-tabs--select-7 ()
  "Select tab by index 7 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 7))

(defun simple-tabs--select-8 ()
  "Select tab by index 8 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 8))

(defun simple-tabs--select-9 ()
  "Select tab by index 9 with `simple-tabs--select-by-num'"
  (interactive)
  (simple-tabs--select-by-num 9))

(defun simple-tabs--helm-select-tab ()
  "Select a tab to open with helm"
  (interactive)
  (helm
   :buffer "*Helm Open Tab*"
   :sources (helm-build-sync-source "Tabs:"
              :candidates (lambda () (let ((buffers (funcall tab-line-tabs-function)))
                                       (mapcar #'buffer-name buffers)))
              :action '(("Open tab" . (lambda (candidate) (switch-to-buffer candidate t t)))))))

(defun simple-tabs--close-other ()
  "Close all other tabs."
  (interactive)
  (let ((buffers (funcall tab-line-tabs-function))
        (current-window (get-buffer-window (current-buffer))))
    (mapc
     (lambda (buffer) (unless (equal buffer (current-buffer))
                        (kill-buffer buffer)))
     buffers)
    (mapc
     (lambda (window) (unless (equal current-window window) (delete-window window)))
     (get-buffer-window-list (current-buffer))))
  )

(defun simple-tabs--close-non-visible ()
  "Close all non visible tabs."
  (interactive)
  (let ((buffers (funcall tab-line-tabs-function)))
    (mapc
     (lambda (buffer) (unless (or (equal buffer (current-buffer)) (get-buffer-window buffer))
                             (kill-buffer buffer)))
     buffers))
  )

(defun simple-tabs-mode--exclude-buffer-show-f ()
  (let* ((buffers (projectile-project-buffers)))
    (-filter
     (lambda (buffer)
       (not (-first
             (lambda (regex) (string-match-p regex (buffer-name buffer)))
             simple-tabs-excluded-buffers-regexp)))
     buffers)
    ))

(defun simple-tabs-mode--unicode-number (str)
  "Return a nice unicode representation of a single-digit number STR."
  (cond
   ((string= "1" str) "➊")
   ((string= "2" str) "➋")
   ((string= "3" str) "➌")
   ((string= "4" str) "➍")
   ((string= "5" str) "➎")
   ((string= "6" str) "➏")
   ((string= "7" str) "➐")
   ((string= "8" str) "➑")
   ((string= "9" str) "➒")
   ((string= "10" str) "➓")
   (t (format "(%s)" str))))

(defun simple-tabs-mode--numbered-names (buffer buffers)
  (let* ((index (+ (-elem-index buffer buffers) 1))
         (name (buffer-name buffer))
         (str_repr (simple-tabs-mode--unicode-number (int-to-string index))))
    (format " %s %s " str_repr name)))

(defun simple-tabs-mode--turn-on ()
  "Turn on `simple-tabs-mode' in all pertinent buffers.
Temporary buffers, buffers whose names begin with a space, buffers
under major modes that are either mentioned in `simple-tabs-disabled-in-modes',
or mentioned in `simple-tabs-disabled-in-buffers-regexp',
or have a non-nil `simple-tabs-exclude' property on their symbol,
and buffers that have a non-nil buffer-local value
of `simple-tabs-exclude', are exempt from `simple-tabs-mode'."
  (unless (or (minibufferp)
              (string-match-p "\\` " (buffer-name))
              (not (projectile-project-p))
              (-filter (lambda (name) (string-match-p name (buffer-name))) simple-tabs-disabled-in-buffers-regexp)
              (memq major-mode simple-tabs-disabled-in-modes)
              (get major-mode 'simple-tabs-exclude)
              (buffer-local-value 'simple-tabs-exclude (current-buffer)))
    (simple-tabs-mode 1)))


;; Map
(defvar simple-tabs-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") 'simple-tabs--helm-select-tab)
    (define-key map (kbd "D") 'simple-tabs--close-other)
    (define-key map (kbd "V") 'simple-tabs--close-non-visible)
    (define-key map (kbd "h") 'simple-tabs--switch-left)
    (define-key map (kbd "l") 'simple-tabs--switch-right)
    (define-key map (kbd "1") 'simple-tabs--select-1)
    (define-key map (kbd "2") 'simple-tabs--select-2)
    (define-key map (kbd "3") 'simple-tabs--select-3)
    (define-key map (kbd "4") 'simple-tabs--select-4)
    (define-key map (kbd "5") 'simple-tabs--select-5)
    (define-key map (kbd "6") 'simple-tabs--select-6)
    (define-key map (kbd "7") 'simple-tabs--select-7)
    (define-key map (kbd "8") 'simple-tabs--select-8)
    (define-key map (kbd "9") 'simple-tabs--select-9)
    map)
  "Simple-tabs-mode keymap after prefix")
(fset 'simple-tabs-command-map simple-tabs-command-map)

(defvar simple-tabs-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map simple-tabs-keymap-prefix simple-tabs-command-map)
    map)
  "Keymap for simple-tabs mode.")


;; Compatibility

(with-eval-after-load 'which-key
  ;; rename first binding for tabs in whichkey
  (push '(("\\(.*\\)1" . "simple-tabs--select-1") .
          ("\\11..9" . "select tab 1..9"))
        which-key-replacement-alist)
  ;; hide other tab select bindings
  (push '((nil . "simple-tabs--select-[2-9]") . t)
        which-key-replacement-alist))


;; Autoloads
;;;###autoload
(defvar-local simple-tabs-exclude nil)

;;;###autoload
(define-minor-mode simple-tabs-mode
  "Toggle display of tab line in the windows displaying the current buffer."
  :lighter nil
  :keymap simple-tabs-mode-map
  ;; TODO: probably not the best place to set this up. But it would rarely be run more than once
  (setq tab-line-auto-hscroll nil
        tab-line-close-button-show nil
        tab-line-new-tab-choice nil
        tab-line-tab-name-function 'simple-tabs-mode--numbered-names
        tab-line-left-button nil
        tab-line-right-button nil
        tab-line-tabs-function 'simple-tabs-mode--exclude-buffer-show-f
        tab-line-tabs-buffer-list-function (lambda () (current-buffer)))
  (let ((default-value '(:eval (tab-line-format))))
    (if simple-tabs-mode
        ;; Preserve the existing tab-line set outside of this mode
        (unless tab-line-format
          (setq tab-line-format default-value))
      ;; Reset only values set by this mode
      (when (equal tab-line-format default-value)
        (setq tab-line-format nil)))))

;;;###autoload
(define-globalized-minor-mode global-simple-tabs-mode
  simple-tabs-mode simple-tabs-mode--turn-on)

(provide 'simple-tabs)
