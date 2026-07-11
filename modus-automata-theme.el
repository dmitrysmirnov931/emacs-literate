;;; modus-automata-theme.el --- Modus theme using NieR:Automata colors -*- lexical-binding:t -*-

;; A light Modus derivative whose palette is drawn from `automata-theme.el',
;; roughly based on NieR:Automata's colors.  See the Modus manual for details
;; on building on top of the themes: <https://protesilaos.com/emacs/modus-themes>.

;;; Code:

(require 'modus-themes)

(defvar modus-automata-palette-user nil
  "Like `modus-automata-palette-overrides' for user-defined entries.")

(defconst modus-automata-palette-overrides
  '(;; Automata named colors
    (automata-grey         "#bab5a1")
    (automata-orange       "#ce664d")
    (automata-dark-grey    "#898776")
    (automata-brown        "#877861")
    (automata-dark-brown   "#454138")
    (automata-indigo       "#2a0d83")
    (automata-second-grey  "#7a766f")
    (automata-light-yellow "#ece2b1")
    (automata-gold         "#af5f00")
    (automata-white        "#ffffff")
    (automata-grey-light   "#c6c1ae")

    ;; Basic values
    (bg-main      automata-grey)
    (bg-dim       automata-dark-grey)
    (fg-main      automata-dark-brown)
    (fg-dim       automata-second-grey)
    (fg-alt       automata-indigo)
    (bg-active    automata-brown)
    (bg-inactive  automata-dark-grey)
    (border       automata-dark-brown)

    ;; Restrict every accent to the automata palette, so faces that use
    ;; named colors directly stay within the theme.
    (red             automata-orange)
    (red-warmer      automata-orange)
    (red-cooler      automata-orange)
    (red-faint       automata-orange)
    (red-intense     automata-orange)
    (green           automata-brown)
    (green-warmer    automata-brown)
    (green-cooler    automata-brown)
    (green-faint     automata-second-grey)
    (green-intense   automata-brown)
    (yellow          automata-gold)
    (yellow-warmer   automata-gold)
    (yellow-cooler   automata-gold)
    (yellow-faint    automata-gold)
    (yellow-intense  automata-gold)
    (blue            automata-indigo)
    (blue-warmer     automata-indigo)
    (blue-cooler     automata-indigo)
    (blue-faint      automata-indigo)
    (blue-intense    automata-indigo)
    (magenta         automata-indigo)
    (magenta-warmer  automata-indigo)
    (magenta-cooler  automata-indigo)
    (magenta-faint   automata-second-grey)
    (magenta-intense automata-indigo)
    (cyan            automata-brown)
    (cyan-warmer     automata-brown)
    (cyan-cooler     automata-brown)
    (cyan-faint      automata-second-grey)
    (cyan-intense    automata-brown)
    (rust            automata-orange)
    (gold            automata-gold)
    (olive           automata-brown)
    (slate           automata-indigo)
    (indigo          automata-indigo)
    (maroon          automata-orange)
    (pink            automata-orange)

    ;; General mappings.  cursor, err, warning and info are intentionally
    ;; omitted: their Modus defaults already resolve through the accent remaps
    ;; above (cursor->fg-main, err->orange, warning->gold, info->brown).
    (fringe    automata-grey)
    (keybind   automata-gold)
    (fg-region automata-grey)
    (bg-region automata-dark-brown)
    (fg-prompt automata-gold)

    ;; Code mappings -- mirror automata's font-lock choices
    (comment      automata-second-grey)
    (string       automata-orange)
    (docstring    automata-orange)
    (constant     automata-orange)
    (keyword      automata-gold)
    (builtin      automata-gold)
    (preprocessor automata-dark-brown)
    (type         automata-dark-brown)
    (fnname       automata-dark-brown)
    (fnname-call  automata-dark-brown)
    (variable     automata-dark-brown)
    (variable-use automata-dark-brown)
    (property     automata-dark-brown)
    (rx-construct automata-orange)
    (rx-backslash automata-gold)

    ;; Mode line -- light text on dark-brown, as in automata
    (bg-mode-line-active       automata-dark-brown)
    (fg-mode-line-active       automata-grey)
    (border-mode-line-active   automata-dark-brown)
    (bg-mode-line-inactive     automata-second-grey)
    (fg-mode-line-inactive     automata-dark-brown)
    (border-mode-line-inactive automata-dark-grey)

    ;; Line numbers -- gold, like automata
    (fg-line-number-active   automata-gold)
    (fg-line-number-inactive automata-gold)
    (bg-line-number-active   automata-grey)
    (bg-line-number-inactive automata-grey)

    ;; Current line / completion candidate -- readable on light bg
    (bg-hl-line    automata-light-yellow)
    (bg-completion automata-light-yellow)

    ;; Search -- white on gold for the current match (automata isearch)
    (bg-search-current automata-gold)
    (fg-search-current automata-white)
    (bg-search-lazy    automata-light-yellow)

    ;; Parens -- white on orange for the match (distinct from search),
    ;; gentle wash for the surrounding expression
    (bg-paren-match      automata-orange)
    (fg-paren-match      automata-white)
    (bg-paren-expression automata-light-yellow)

    ;; Accents, links, completion-match highlights
    (accent-0 automata-indigo)
    (accent-1 automata-orange)
    (accent-2 automata-gold)
    (accent-3 automata-dark-brown)

    (fg-completion-match-0 automata-indigo)
    (fg-completion-match-1 automata-orange)
    (fg-completion-match-2 automata-gold)
    (fg-completion-match-3 automata-dark-brown)

    (fg-link         automata-indigo)
    (fg-link-visited automata-orange)

    ;; Headings
    (fg-heading-0 automata-indigo)
    (fg-heading-1 automata-dark-brown)
    (fg-heading-2 automata-gold)
    (fg-heading-3 automata-orange)
    (fg-heading-4 automata-dark-grey)
    (fg-heading-5 automata-brown)
    (fg-heading-6 automata-gold)
    (fg-heading-7 automata-orange)
    (fg-heading-8 automata-second-grey))
  "Palette overrides for the `modus-automata' theme.")

(defconst modus-automata-faces
  '(`(magit-diff-context-highlight ((,c :background ,automata-grey-light)))
    `(corfu-default ((,c :inherit modus-themes-fixed-pitch :background ,bg-main)))
    `(corfu-popupinfo ((,c :inherit modus-themes-fixed-pitch :background ,bg-main)))
    ;; lsp symbol highlights match the region face.  corfu-current and
    ;; vertico-current are left to Modus's default (bg-completion).
    `(lsp-face-highlight-textual ((,c :inherit region)))
    `(lsp-face-highlight-read ((,c :inherit region)))
    `(lsp-face-highlight-write ((,c :inherit region)))
    `(vertico-group-title ((,c :slant italic :foreground ,automata-gold)))
    `(completions-group-title ((,c :inherit modus-themes-slant :height 0.9 :foreground ,automata-gold)))
    ;; lsp-mode breadcrumb: black prefix, keyword-colored path and symbols
    `(lsp-headerline-breadcrumb-project-prefix-face ((,c :weight bold :foreground "#000000")))
    `(lsp-headerline-breadcrumb-unknown-project-prefix-face ((,c :weight bold :foreground "#000000")))
    `(lsp-headerline-breadcrumb-path-face ((,c :foreground ,keyword)))
    `(lsp-headerline-breadcrumb-symbols-face ((,c :weight bold :foreground ,keyword))))
  "Custom face overrides for the `modus-automata' theme.")

(modus-themes-theme
 'modus-automata
 'modus-themes
 "A light Modus theme using NieR:Automata's colors."
 'light
 'modus-themes-operandi-palette
 'modus-automata-palette-user
 'modus-automata-palette-overrides
 'modus-automata-faces)

(provide-theme 'modus-automata)
(provide 'modus-automata-theme)

;;; modus-automata-theme.el ends here
