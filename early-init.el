;;; early-init.el --- Pre-GUI startup tuning  -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)

(defvar my--file-name-handler-alist file-name-handler-alist)
(defvar my--vc-handled-backends vc-handled-backends)
(setq file-name-handler-alist nil
      vc-handled-backends nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my--file-name-handler-alist
                  vc-handled-backends my--vc-handled-backends))
          101)

(setq default-frame-alist
      '((tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (background-color . "#ffffff")
        (foreground-color . "#000000")))
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

(setq inhibit-compacting-font-caches t)
(setq bidi-inhibit-bpa t)
(setq-default bidi-paragraph-direction 'left-to-right)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      inhibit-x-resources t)

(setq native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation t
      load-prefer-newer t)
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "var/eln-cache/" user-emacs-directory)))


