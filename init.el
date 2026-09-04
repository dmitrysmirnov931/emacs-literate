;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t; -*-

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

;;; Completion.
;;
;; Emacs 31 turns the builtin "*Completions*" buffer into a full replacement
;; for vertico (minibuffer UI), corfu (in-buffer popup), marginalia
;; (annotations) and orderless (matching).  The two options that make it work
;; are new in 31: `completion-eager-display' shows the buffer without pressing
;; TAB, and `completion-eager-update' refreshes it as you type.  Both default
;; to `auto', meaning "only if the completion table asks for it", and almost
;; nothing asks.  See
;; https://rahuljuliato.com/posts/completions-buffer-is-now-enough

(defun my/flex-noinsert-try-completion (string table pred point)
  "Flex `try-completion' that never auto-extends the input on TAB.

The stock `flex' style does two jobs: it filters candidates by fuzzy
match, and its `try-completion' merges the survivors and inserts their
common expansion.  With `tab-always-indent' set to `complete' that merge
happens on TAB, so Emacs silently types a candidate -- often a distant,
wrong one -- before \"*Completions*\" is ever shown.  Eglot works around
this with its own `eglot--dumb-flex', which skips the merge but also
loses flex's relevance scoring.

This wrapper keeps flex's filtering and scoring and drops only the merge:

  - no candidates          -> nil, no match
  - exactly one candidate  -> complete it fully, the one case where the
                              merge cannot be wrong
  - two or more candidates -> return STRING unchanged, so TAB only pops
                              \"*Completions*\" and inserts nothing

STRING, TABLE, PRED and POINT are the usual `try-completion' arguments."
  (let ((all (completion-flex-all-completions string table pred point)))
    (cond
     ((null all) nil)
     ((= (safe-length all) 1)
      (let ((sole (car all)))
        (if (string= sole string) t (cons sole (length sole)))))
     (t (cons string point)))))

(add-to-list 'completion-styles-alist
             '(flex-noinsert
               my/flex-noinsert-try-completion
               completion-flex-all-completions
               "Flex matching that never extends input on TAB."))

;; Reuse flex's metadata tweak so "*Completions*" sorts by flex score rather
;; than alphabetically.
(put 'flex-noinsert 'completion--adjust-metadata
     'completion--flex-adjust-metadata)

(defun my/minibuffer-truncate-lines ()
  "Keep minibuffer lines unwrapped."
  (setq truncate-lines t))

(use-package minibuffer
  :ensure nil
  :bind (:map minibuffer-visible-completions-up-down-map
              ("C-n" . minibuffer-next-completion)
              ("C-p" . minibuffer-previous-completion)
              :map completion-in-region-mode-map
              ("C-n" . minibuffer-next-completion)
              ("C-p" . minibuffer-previous-completion))
  :hook ((minibuffer-setup . cursor-intangible-mode)
         (minibuffer-setup . my/minibuffer-truncate-lines))
  :custom
  (tab-always-indent 'complete)
  (completion-auto-help t)
  (completion-auto-select t)
  (completion-eager-display t)
  (completion-eager-update t)
  (completion-show-help nil)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completion-styles '(partial-completion flex initials))
  ;; Only Eglot gets the no-insert variant.  The minibuffer keeps stock flex,
  ;; where the merge is harmless because you can see what it did.
  (completion-category-overrides '((eglot-capf (styles flex-noinsert))))
  (completions-format 'one-column)
  (completions-max-height 15)
  (completions-sort 'historical)
  (completions-detailed t)
  (minibuffer-visible-completions 'up-down)
  ;; Recursive minibuffers plus the depth indicator that makes them readable:
  ;; the prompt gains a [2] so you know how deep you are.
  (enable-recursive-minibuffers t)
  (minibuffer-depth-indicate-mode t)
  (minibuffer-electric-default-mode t)
  (minibuffer-prompt-properties
   '(read-only t intangible t cursor-intangible t face minibuffer-prompt)))

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

;; In-buffer completion is the same "*Completions*" buffer: `tab-always-indent'
;; is `complete' above, so TAB indents the line if it needs it, then completes.
;; Completion Preview is the builtin stand-in for `corfu-auto', showing the
;; leading candidate inline as you type.  TAB is unbound in its keymap so it
;; keeps popping "*Completions*" instead of silently accepting the preview.
(use-package completion-preview
  :ensure nil
  :hook (after-init . global-completion-preview-mode)
  :bind (:map completion-preview-active-mode-map
              ("TAB"   . nil)
              ("<tab>" . nil)
              ("M-i"   . completion-preview-insert)
              ("M-n"   . completion-preview-next-candidate)
              ("M-p"   . completion-preview-prev-candidate))
  :custom
  (completion-preview-minimum-symbol-length 2)
  (completion-preview-idle-delay 0.15))

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

;; Emacs 31 does treesit-auto's job builtin: `treesit-enabled-modes' rewrites
;; `major-mode-remap-alist' from `treesit-major-mode-remap-alist', so .py and
;; .cs open in their ts-modes without per-mode `:mode' entries, and
;; `treesit-auto-install-grammar' fetches missing grammars on demand.
(use-package treesit
  :ensure nil
  :custom
  (treesit-enabled-modes t)
  (treesit-auto-install-grammar 'ask))

(use-package eglot
  :ensure nil
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l f" . eglot-format-buffer)
              ("C-c l i" . eglot-find-implementation)
              ("C-c l t" . eglot-find-typeDefinition)
              ("C-c l R" . eglot-reconnect)
              ("C-c l q" . eglot-shutdown)
              ("C-c d"   . eldoc-doc-buffer))
  :custom
  (eglot-autoshutdown t)
  (eglot-extend-to-xref t)
  (eglot-sync-connect 1)
  (eglot-report-progress 'messages)
  ;; The events buffer allocates heavily on chatty servers; keep it empty
  ;; unless something actually needs debugging.
  (eglot-events-buffer-config '(:size 0 :format short))
  :config
  ;; Eglot's stock C# alternatives are omnisharp, OmniSharp, then csharp-ls.
  ;; Only csharp-ls is on PATH here, and the old `lsp-disabled-clients'
  ;; explicitly rejected it, so prefer the OmniSharp build already on disk.
  (let ((omnisharp (expand-file-name "lsp-servers/omnisharp-roslyn/latest/OmniSharp"
                                     my/var-dir)))
    (add-to-list 'eglot-server-programs
                 `((csharp-mode csharp-ts-mode)
                   . ,(eglot-alternatives
                       `((,omnisharp "-lsp") ("omnisharp" "-lsp") ("csharp-ls")))))))

;; emacs-lsp-booster converts server JSON into elisp bytecode out of process.
;; Eglot's supported integration lives outside ELPA.
;; See https://github.com/jdtsmith/eglot-booster
(use-package eglot-booster
  :vc (:url "https://github.com/jdtsmith/eglot-booster" :rev :newest)
  :if (executable-find "emacs-lsp-booster")
  :defer t
  :init
  ;; Soft-require rather than `:after', which expands to a hard `require'
  ;; inside Eglot's load hook: a failed VC install would then take Eglot
  ;; down with it instead of degrading to an unboosted server.
  (with-eval-after-load 'eglot
    (when (require 'eglot-booster nil t)
      (eglot-booster-mode))))

;; Eglot renders LSP markdown documentation with `gfm-view-mode' when
;; markdown-mode is installed; see `eglot-documentation-renderer'.
(use-package markdown-mode
  :mode ("\\.md\\'" . gfm-mode)
  :custom
  (markdown-fontify-code-blocks-natively t))

(use-package csharp-mode
  :ensure nil
  :hook (csharp-ts-mode . eglot-ensure))

(use-package python
  :ensure nil
  :hook (python-ts-mode . my/python-setup)
  :init
  (defun my/python-find-venv ()
    "Return the absolute path to a `venv' directory at or above the buffer file."
    (when-let* ((dir (and buffer-file-name
                          (locate-dominating-file buffer-file-name "venv"))))
      (expand-file-name "venv" dir)))

  (defun my/python-setup ()
    "Point Python tooling at the project's venv, then start Eglot.
Prepending the venv's bin to `exec-path' is what lets Eglot find the
project-local `basedpyright-langserver', which is already first in Eglot's
list of Python alternatives.  `eglot-workspace-configuration' then tells
the server which interpreter to analyse against, the job that
`lsp-pyright-venv-path' used to do."
    (when-let* ((venv (my/python-find-venv))
                (bin  (expand-file-name "bin" venv)))
      (setq-local exec-path (cons bin exec-path))
      (setq-local python-shell-virtualenv-root venv)
      (setq-local eglot-workspace-configuration
                  `(:python (:pythonPath ,(expand-file-name "python" bin))))
      (setenv "VIRTUAL_ENV" venv))
    (eglot-ensure))
  :custom
  (python-indent-guess-indent-offset-verbose nil))

;; Eglot's default Haskell contact is already
;; ("haskell-language-server-wrapper" "--lsp"), so lsp-haskell had nothing
;; left to configure.
(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :hook ((haskell-mode . eglot-ensure)
         (haskell-mode . interactive-haskell-mode))
  :custom
  (haskell-process-type 'cabal-repl)
  (haskell-process-suggest-remove-import-lines t)
  (haskell-process-auto-import-loaded-modules t))

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
    (when-let* ((win (get-buffer-window (process-buffer proc))))
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
