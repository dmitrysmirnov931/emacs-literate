(require 'package)
(add-to-list 'package-archives '("melpa"        . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages") t)
(setq package-archive-priorities
	'(("gnu"          . 99)
	  ("nongnu"       . 80)
	  ("melpa"        . 60)
	  ("melpa-stable" . 40))
	package-install-upgrade-built-in t)

(require 'use-package)
(setq use-package-vc-prefer-newest t
      use-package-expand-minimally t
      use-package-compute-statistics nil
      use-package-enable-imenu-support t
      use-package-always-ensure t)

(use-package gcmh
  :hook (after-init . gcmh-mode)
  :custom
  (gcmh-idle-delay 'auto)
  (gcmh-auto-idle-delay-factor 10)
  (gcmh-high-cons-threshold (* 32 1024 1024)))

(use-package emacs
  :ensure nil
  :custom
  (read-process-output-max (* 10 1024 1024))
  (process-adaptive-read-buffering nil)
  (jit-lock-defer-time 0)
  (fast-but-imprecise-scrolling t)
  (redisplay-skip-fontification-on-input t)
  (idle-update-delay 1.0)
  :config
  (add-hook 'emacs-startup-hook
  	    (lambda ()
	      (message "Emacs started in %.2fs with %d GCs."
		       (float-time (time-subtract after-init-time before-init-time))
		       gcs-done))))

(use-package files
  :ensure nil
  :config
  (defconst my/etc-dir       (expand-file-name "etc/" user-emacs-directory))
  (defconst my/var-dir       (expand-file-name "var/" user-emacs-directory))
  (defconst my/backup-dir    (expand-file-name "backups/" user-emacs-directory))
  (defconst my/auto-save-dir (expand-file-name "auto-save/" user-emacs-directory))
  (defconst my/eln-cache-dir (expand-file-name "eln-cache/" user-emacs-directory))
  (dolist (dir (list my/etc-dir my/var-dir my/backup-dir my/auto-save-dir my/eln-cache-dir))
    (make-directory dir t))

  (setq backup-by-copying t
	version-control t
	delete-old-versions t
	history-delete-duplicates t
	kept-new-versions 6
	kept-old-versions 2
	vc-make-backup-files t)

  (setq custom-file                    (expand-file-name "custom.el" my/etc-dir)
  	backup-directory-alist         `(("." . ,my/backup-dir))
  	auto-save-file-name-transforms `((".*" ,my/auto-save-dir t))
  	auto-save-list-file-prefix     (expand-file-name "saves-" my/auto-save-dir)
  	savehist-file                  (expand-file-name "savehist.el" my/var-dir)
  	recentf-save-file              (expand-file-name "recentf.el" my/var-dir)
  	bookmark-default-file          (expand-file-name "bookmarks.el" my/var-dir)
  	url-history-file               (expand-file-name "url/history" my/var-dir)
  	project-list-file              (expand-file-name "projects.el" my/var-dir)
	save-place-file                (expand-file-name "save-place.el" my/var-dir)
  	tramp-persistency-file-name    (expand-file-name "tramp.el" my/var-dir))
  (when (file-exists-p custom-file) (load custom-file nil t))

  (with-eval-after-load 'lsp-mode
    (setq lsp-session-file       (expand-file-name "lsp-session" my/var-dir)
	  lsp-server-install-dir (expand-file-name "lsp-servers/" my/var-dir)))

  ;; Compress auto-save/backup file names so deep paths don't overflow.
  (defun my/make-hashed-auto-save-file-name-a (fn)
    "Compress the auto-save file name so paths don't get too long."
    (let ((buffer-file-name
           (if (or (null buffer-file-name)
                   (find-file-name-handler buffer-file-name 'make-auto-save-file-name))
               buffer-file-name
             (sha1 buffer-file-name))))
      (funcall fn)))
  (advice-add #'make-auto-save-file-name :around #'my/make-hashed-auto-save-file-name-a)

  (defun my/make-hashed-backup-file-name-a (fn file)
    "A few places use the backup file name so paths don't get too long."
    (let ((alist backup-directory-alist)
          backup-directory)
      (while alist
        (let ((elt (car alist)))
          (if (string-match (car elt) file)
              (setq backup-directory (cdr elt) alist nil)
            (setq alist (cdr alist)))))
      (let ((file (funcall fn file)))
        (if (or (null backup-directory)
                (not (file-name-absolute-p backup-directory)))
            file
          (expand-file-name (sha1 (file-name-nondirectory file))
                            (file-name-directory file))))))
  (advice-add #'make-backup-file-name-1 :around #'my/make-hashed-backup-file-name-a))

(use-package emacs
  :ensure nil
  :init
  (electric-pair-mode t)
  (show-paren-mode t)
  (global-auto-revert-mode t)
  (save-place-mode t)
  (delete-selection-mode t)
  ; (global-hl-line-mode t)
  (global-so-long-mode t)
  (winner-mode t)
  (size-indication-mode 1)
  (defun switch-to-minibuffer ()
    "Switch to minibuffer window."
    (interactive)
    (if (active-minibuffer-window)
        (select-window (active-minibuffer-window))
      (error "Minibuffer is not active")))
  (defun my/keyboard-quit-dwim ()
    "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
    (interactive)
    (cond
     ((region-active-p)
      (keyboard-quit))
     ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
     ((> (minibuffer-depth) 0)
      (abort-recursive-edit))
     (t
      (keyboard-quit))))
  :bind
  (("C-c o" . switch-to-minibuffer)
   ("C-g"   . my/keyboard-quit-dwim))
  :hook ((prog-mode text-mode) . display-line-numbers-mode)
  :custom
  (truncate-lines t)
  (line-spacing 1)
  (ring-bell-function 'ignore)
  (use-short-answers t)
  (ffap-machine-p-known 'reject)
  (global-text-scale-adjust-resizes-frames nil)
  (scroll-conservatively most-positive-fixnum)
  (eldoc-echo-area-use-multiline-p nil)
  (display-line-numbers-type 'relative)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (save-interprogram-paste-before-kill t)
  (imenu-auto-rescan t)
  (mode-line-compact nil)
  (mode-line-position-column-line-format '(" %l:%c"))
  :config
  (prefer-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-face-attribute 'default nil :family "PragmataPro Mono Liga" :height 170)
  (set-face-attribute 'fixed-pitch nil :family "PragmataPro Mono Liga" :height 170)
  (set-face-attribute 'variable-pitch nil :family "PragmataPro Mono Liga" :height 170)
  (put 'downcase-region 'disabled nil))

(use-package exec-path-from-shell
  :config
  (dolist (var '("DOTNET_ROOT"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

(use-package savehist
  :ensure nil
  :hook (after-init . savehist-mode)
  :custom
  (history-length 1000)
  (savehist-additional-variables '(kill-ring search-ring regexp-search-ring)))

(use-package recentf
  :ensure nil
  :hook (after-init . recentf-mode)
  :custom
  (recentf-max-saved-items 300))

(use-package which-key
  :ensure nil
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.5)
  (which-key-add-column-padding 1)
  (which-key-sort-order 'which-key-key-order-alpha))

(use-package vertico
  :hook (after-init . vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  (vertico-resize nil))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
	      ("RET"   . vertico-directory-enter)
	      ("DEL"   . vertico-directory-delete-char)
	      ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :hook (after-init . marginalia-mode))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package consult
  :bind (;; C-x — buffers & bookmarks
         ("C-x b"   . consult-buffer)
         ("C-x B" . consult-buffer-other-window)
         ("C-x p b" . consult-project-buffer)
         ("C-x r b" . consult-bookmark)
         ;; M-g — goto map
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g o"   . consult-outline)
         ("M-g m"   . consult-mark)
         ("M-g f"   . consult-flymake)
         ;; M-s — search map
         ("M-s r"   . consult-ripgrep)
         ("M-s d"   . consult-find)
         ;; Misc
         ("s-f"     . consult-line)
         ("M-y"     . consult-yank-pop)
         ("C-c r"   . consult-recent-file))
  :custom
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  (consult-narrow-key "<")
  :config
  (consult-customize
   consult-ripgrep consult-grep consult-git-grep
   consult-buffer consult-recent-file
   :preview-key '(:debounce 0.3 any)))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   :map minibuffer-local-map
   ("C-c C-c" . embark-collect)
   ("C-c C-e" . embark-export))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package corfu
  :hook (after-init . global-corfu-mode)
  :bind (:map corfu-map
              ("TAB"       . corfu-next)
              ("<tab>"     . corfu-next)
              ("S-TAB"     . corfu-previous)
              ("<backtab>" . corfu-previous))
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.15)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay '(0.4 . 0.2))
  (tab-always-indent 'complete)
  :config
  (corfu-popupinfo-mode 1)
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (unless (bound-and-true-p vertico--input)
                (setq-local corfu-auto nil)
                (corfu-mode 1)))))

(use-package emacs
  :ensure nil
  :config
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook
                (lambda () (load-theme 'modus-automata t)))
    (load-theme 'modus-automata t)))

(use-package ghostel
  :bind (("s-l" . my/ghostel-toggle)
         :map ghostel-semi-char-mode-map
         ("C-k"  . my/ghostel-send-C-k-and-kill)
         ("M-p" . (lambda () (interactive) (ghostel-send-key "p" "ctrl")))
         ("M-n" . (lambda () (interactive) (ghostel-send-key "n" "ctrl")))
         :map project-prefix-map
         ("m" . ghostel-project)
         ("M" . ghostel-project-list-buffers))
  :config
  (defun my/ghostel-toggle ()
    "Open ghostel, or go back to the previous buffer if it's the only window."
    (interactive)
    (if (derived-mode-p 'ghostel-mode)
        (switch-to-prev-buffer)
      (ghostel)))

  (defun my/ghostel-send-C-k-and-kill ()
    "Send `C-k' to ghostel.
Like normal Emacs `C-k'.  Kill to end of line and put content in kill-ring."
    (interactive)
    (kill-ring-save (point) (line-end-position))
    (ghostel-send-key "k" "ctrl"))

  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
  (add-to-list 'project-switch-commands '(ghostel-project-list-buffers "Ghostel buffers") t)
  (add-to-list 'ghostel-eval-cmds '("magit-status-setup-buffer" magit-status-setup-buffer)))

(use-package ghostel-eshell
  :ensure nil
  :hook (eshell-load . ghostel-eshell-visual-command-mode))

(use-package ghostel-compile
  :ensure nil
  :hook (after-init . ghostel-compile-global-mode))

(use-package ghostel-comint
  :ensure nil
  :hook (after-init . ghostel-comint-global-mode))

(use-package minions
  :hook (after-init . minions-mode)
  :custom (minions-mode-line-lighter "≡"))

(use-package expand-region
  :bind ("C-=" . er/expand-region))

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (global-treesit-auto-mode))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-use-plists t)
  (setq lsp-keymap-prefix "C-c l")
  :hook ((lsp-mode . lsp-enable-which-key-integration))
  :config
  (setq
        lsp-idle-delay 0.5
        lsp-log-io nil
        lsp-completion-provider :none
        lsp-enable-file-watchers nil
        lsp-file-watch-threshold 2000
        lsp-enable-folding nil
        lsp-enable-text-document-color nil
        lsp-enable-on-type-formatting nil
        lsp-enable-indentation nil
        lsp-keep-workspace-alive nil
        lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-enable-symbol-numbers nil
        lsp-headerline-breadcrumb-segments '(project file symbols)
        lsp-modeline-code-actions-enable nil
        lsp-diagnostics-provider :flymake
        lsp-disabled-clients '(ruff csharp-ls))
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
  (add-hook 'lsp-completion-mode-hook #'my/lsp-mode-setup-completion)

  (defun lsp-booster--advice-json-parse (old-fn &rest args)
    (or (when (equal (following-char) ?#)
          (let ((bytecode (read (current-buffer))))
            (when (byte-code-function-p bytecode)
              (funcall bytecode))))
        (apply old-fn args)))
  (advice-add (if (progn (require 'json) (fboundp 'json-parse-buffer))
                  'json-parse-buffer 'json-read)
              :around #'lsp-booster--advice-json-parse)

  (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
    (let ((orig-result (funcall old-fn cmd test?)))
      (if (and (not test?)
               (not (file-remote-p default-directory))
               lsp-use-plists
               (not (functionp 'json-rpc-connection)) ; not native json-rpc
               (executable-find "emacs-lsp-booster"))
          (progn
            (when-let ((command-from-exec-path (executable-find (car orig-result))))
              (setcar orig-result command-from-exec-path))
            (message "Using emacs-lsp-booster for %s!" orig-result)
            (cons "emacs-lsp-booster" orig-result))
        orig-result)))
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command))

(use-package lsp-ui
  :commands lsp-ui-mode
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references]  . lsp-ui-peek-find-references)
              ("C-c d" . lsp-ui-doc-glance))
  :config
  (setq lsp-ui-doc-enable nil
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-show-code-actions nil))

(use-package consult-lsp
  :after (consult lsp-mode)
  :bind (:map lsp-mode-map
              ([remap xref-find-apropos] . consult-lsp-symbols)))

(use-package csharp-mode
  :ensure nil
  :mode ("\\.cs\\'" . csharp-ts-mode)
  :hook (csharp-ts-mode . lsp-deferred))

(use-package lsp-pyright
  :init
  (setq lsp-pyright-langserver-command "basedpyright")
  :config
  (setq lsp-pyright-multi-root nil))

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-ts-mode)
  :hook (python-ts-mode . my/python-setup)
  :init
  (defun my/python-find-venv ()
    "Return the absolute path to a `venv' directory at or above the buffer file."
    (when-let* ((dir (and buffer-file-name
                          (locate-dominating-file buffer-file-name "venv"))))
      (expand-file-name "venv" dir)))

  (defun my/python-setup ()
    "Point Python tooling at the project's venv before LSP starts."
    (when-let* ((venv (my/python-find-venv))
                (bin  (expand-file-name "bin" venv)))
      (setq-local exec-path (cons bin exec-path))
      (setq-local lsp-pyright-venv-path venv)
      (setq-local python-shell-virtualenv-root venv)
      (setenv "VIRTUAL_ENV" venv))
    (require 'lsp-pyright)
    (lsp-deferred))
  :custom
  (python-indent-guess-indent-offset-verbose nil))

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :hook ((haskell-mode . lsp-deferred)
         (haskell-mode . interactive-haskell-mode))
  :custom
  (haskell-process-type 'cabal-repl)
  (haskell-process-suggest-remove-import-lines t)
  (haskell-process-auto-import-loaded-modules t))

(use-package lsp-haskell
  :after lsp-mode
  :custom
  (lsp-haskell-server-path "haskell-language-server-wrapper"))

(use-package avy
  :bind ("s-j" . avy-goto-char-timer))

(use-package diff-hl
  :hook ((after-init . global-diff-hl-mode)
         (after-init . diff-hl-flydiff-mode)))

(use-package magit
  :bind (("C-x g" . magit-status))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-diff-refine-hunk t)
  :config
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

(use-package dired
  :ensure nil
  :custom
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-auto-revert-buffer #'dired-directory-changed-p) ; also see `dired-do-revert-buffer'
  (dired-clean-up-buffers-too t)
  (dired-clean-confirm-killing-deleted-buffers t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (delete-by-moving-to-trash t)
  (dired-create-destination-dirs 'ask)
  (dired-create-destination-dirs-on-trailing-dirsep t)
  (wdired-create-parent-directories t))

(use-package ediff
  :ensure nil
  :custom
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package compile
  :ensure nil
  :init
  (defun my/compilation-select-window (proc)
    "Select the window showing the compilation buffer for PROC."
    (when-let ((win (get-buffer-window (process-buffer proc))))
      (select-window win)))
  :hook (compilation-start . my/compilation-select-window)
  :custom
  (compilation-scroll-output t))

(use-package ace-window
  :bind (("s-o" . ace-window)
         ("s-p" . ace-delete-other-windows)
	 ("s-[" . ace-delete-window))
  :custom
  (aw-minibuffer-flag t)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package sharper
  :bind
  ("C-c c" . sharper-main-transient))

(use-package org
  :ensure nil
  :bind ("C-c a" . org-agenda)
  :custom
  (org-directory "~/org")
  ;; Agenda scans this subdir non-recursively; keeps denote/ and verb/ out.
  (org-agenda-files (list (expand-file-name "agenda" org-directory))))

(use-package verb
  :after org
  :config
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))

(use-package denote
  :bind
  (("C-c n n" . denote)
   ("C-c n o" . denote-open-or-create)
   ("C-c n l" . denote-link)
   ("C-c n b" . denote-backlinks)
   ("C-c n r" . denote-rename-file)
   ("C-c n d" . denote-dired))
  :custom
  (denote-directory "~/org/denote"))

(use-package clutch
  :commands (clutch-query-console clutch-query-sqlite-file)
  :custom
  ;; Omit :password so clutch resolves credentials auth-source, which
  ;; searches ~/.authinfo(.gpg) by :host/:user/:port.  Each connection needs
  ;; a matching line, where the tokens map to the plist keys below:
  ;;   machine HOST login USER port PORT password SECRET
  ;; e.g. for the dev-pg entry:
  ;;   machine 127.0.0.1 login postgres port 5432 password secret
  (clutch-connection-alist
   '(("ownership_graph" . (:backend pg
				    :host "127.0.0.1" :port 5432
				    :user "ownership_graph_user" :database "ownership_graph")))))
