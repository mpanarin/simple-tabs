# Simple tabs

Emacs minor mode for opinionated tabs based on `tab-line-mode`

TODO: finish the readme

## My config in spacemacs

``` emacs-lisp
(use-package simple-tabs
    :load-path "~/projects/personal/elisp/simple-tabs/"
    :demand
    :custom
    (simple-tabs-excluded-buffers-regexp '("magit"
                                           "helm"
                                           "^\*"))
    (simple-tabs-disabled-in-buffers-regexp '("^magit"
                                              "^COMMIT"
                                              "^\*"
                                              "^\ \*"))
    (simple-tabs-disabled-in-modes '(completion-list-mode
                                     helm-mode
                                     help-mode
                                     magit-mode
                                     vterm-mode
                                     ranger-mode
                                     dired-mode))
    :custom-face
    (tab-line ((t (:underline "#83898d" :height 1.0))))
    (tab-line-tab ((t (:inherit tab-line :box (:line-width 1 :color "#282725") :underline "#83898d"))))
    (tab-line-tab-current ((t (:inherit tab-line-tab :box (:line-width 1 :color "#83898d") :underline "#282725"))))
    (tab-line-tab-inactive ((t (:inherit tab-line-tab :overline "#282725"))))
    :bind
    (:map evil-normal-state-local-map ("SPC w t" . simple-tabs-command-map))
    :config
    (global-simple-tabs-mode 1))
```
