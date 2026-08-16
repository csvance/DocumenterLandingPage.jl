# Chrome inventory: everything to theme, with the exact rule

Working checklist for recoloring Documenter's chrome. Every rule below is
written for the light scope `html:root:not(.theme--documenter-dark):
not([class*="theme--catppuccin"])` and the dark scope
`html.theme--documenter-dark` (add `:root` where the note says). Where the
theme's own rule is more specific than a plain selector, the note says so
and the fix mirrors the theme's selector plus the `html:root` prefix.

The colors come from your `--brand-*` palette; the template defines them.
The stock colors you are replacing: dark accent `#1abc9c`, light accent
`#2e63b8`, dark border `#5e6d6f`, light border `#dbdbdb`, dark surfaces
`#282f2f` and `#1f2424`.

## Page

| Element | Selector | Rule |
| --- | --- | --- |
| page background and text | `html:root body` | `background-color: var(--brand-bg); color: var(--brand-text)` |
| links | `html:root a`, `html:root a:hover` | `color: var(--brand-link)` / `--brand-link-hover` |
| headings | `html:root .content h1..h6` | `color: var(--brand-heading)` |
| heading anchors | `html:root h1..h6 .docs-heading-anchor` (+ `:hover`, `:visited`) | heading text is wrapped in these links and otherwise takes the link color |
| horizontal rules | `html:root hr` | `background-color: var(--brand-navbar-border)` |
| selection | `html:root ::selection` | warm background and text |

## Sidebar (the left navigation panel)

| Element | Selector | Rule |
| --- | --- | --- |
| panel background and edge | `html:root #documenter .docs-sidebar` | `background-color: var(--brand-sidebar-bg); border-right: 1px solid var(--brand-sidebar-border)` |
| scrollbar | `html:root #documenter .docs-sidebar` (`scrollbar-color`), `::-webkit-scrollbar-track/thumb` | the stock track is near-white; tie it to the palette |
| package name | `html:root #documenter .docs-sidebar .docs-package-name a` | `color: var(--brand-heading)` |
| search box | `html:root #documenter .docs-sidebar #documenter-search-query` (+ `:focus`) | it is a `<button class="input">`, not a `form.docs-search > input` |
| nav rows | `html:root #documenter .docs-sidebar ul.docs-menu li, ... .tocitem` | the theme paints every row with the page background; set `background-color: transparent` |
| nav row text | `... ul.docs-menu .tocitem` | `color: var(--brand-sidebar-link)` |
| nav row hover | `... ul.docs-menu a.tocitem:hover` | warm hover background and text |
| active section | `... ul.docs-menu li.is-active` and `... li.is-active .tocitem` | the theme's `li.is-active` (background plus top/bottom borders) outranks a generic `li` rule; paint the whole block |
| structure lines | `... ul.docs-menu`, `... ul.docs-menu > li li`, `... li.is-active`, `... ul.internal`, `... .docs-version-selector` | `border-color: var(--brand-sidebar-structure)`; use a divider tone clearly distinct from the panel background |
| version selector | `html:root .docs-version-selector .button.is-static, ... .select select` | warm background, border, text |

## Header bar

| Element | Selector | Rule |
| --- | --- | --- |
| background and rule | `html:root #documenter .docs-main header.docs-navbar` | `background-color: var(--brand-navbar-bg); border-bottom: 1px solid var(--brand-navbar-border)` |
| reach the sides | same rule | the sidebar is 18rem, the content column starts at a 20rem margin, plus 1rem right padding; add `margin-left: -2rem; margin-right: -1rem; padding-left: 2rem; padding-right: 1rem;` |
| breadcrumb | `html:root .breadcrumb a`, `... .breadcrumb li.is-active a` | warm text |

## Content

| Element | Selector | Rule |
| --- | --- | --- |
| inline code | `html:root code` | `background-color: var(--brand-code-bg); color: var(--brand-code-text)`; then `html:root pre code` back to transparent |
| code blocks | `html:root pre`, `html:root .hljs` | warm background and border; the theme's `.hljs` uses `background: initial !important`, so the override needs `!important` too |
| code block border | `html:root .content pre` | the theme's `.content pre` (2px stock border) outranks the plain `pre` rule |
| links inside code | `html:root .content a code` | `color: var(--brand-link)`; the theme's rule outranks the plain `a` rule |
| code copy button | `html:root pre .copy-button:hover, :focus` | `color: var(--brand-link)` |
| blockquote | `html:root .content blockquote` | warm background and left border |
| tables | `html:root table td, th` | `border-color: var(--brand-table-border)`; header row background |
| footer | `html:root #documenter .docs-main .docs-footer` | `color: var(--brand-footer)`; its top border needs the structure rule |
| syntax tokens | `html:root .hljs-comment`, `.hljs-keyword`, `.hljs-string`, ... | a warm pass over the highlight.js token classes; reuse palette tones |
| line numbers | `html.theme--documenter-dark:root` on `--ln-bg`, `--ln-fg`, `--ln-fg-hover`, `--ln-border`, `--ln-hl-*` | DocumenterCodeBlocks tokens load after your CSS; `--ln-bg` must match the code block background |

## Docstrings (the API page)

| Element | Selector | Rule |
| --- | --- | --- |
| box | `html:root #documenter details.docstring` | `border: 2px solid var(--brand-sidebar-border)`; the `#documenter` prefix is required to beat the theme's scoped rule |
| summary bar | `html:root #documenter details.docstring > summary` | warm background, bottom border, text |
| section rule | `html:root #documenter details.docstring > section` | `border-bottom: 1px solid var(--brand-sidebar-border)` |
| chevron | `html:root #documenter details.docstring > summary::before` | the stock color is the accent blue; use the link color |
| source links | `html:root #documenter details.docstring > section > a.docs-sourcelink` (+ `.is-link`) | the theme paints these tags with the accent; make them quiet warm tags |
| admonitions | `html:root .admonition` (+ `.is-info`, `.is-success`, `.is-warning`, `.is-danger`, `.is-compat`, `.is-todo`) | warm background, header text, and variant accents on both the left and top borders; the theme sets the background on each variant class with higher specificity, so mirror it there |

## Settings modal and theme picker

| Element | Selector | Rule |
| --- | --- | --- |
| card | `html:root .modal-card`, `html:root .modal-card-body`, `html:root .modal-card-head` | warm backgrounds and borders |
| title and label | `html:root .modal-card-title`, `html:root #documenter-settings .label` | `color: var(--brand-heading)` |
| picker select | `html:root #documenter-settings .select select` | warm background, border, text |
| links and rules | `html:root #documenter-settings a`, `... hr` | warm |
| remove catppuccin options | JS in `brand.js` | delete `option[value^="catppuccin"]` from `#documenter-themepicker` on `DOMContentLoaded`; reset a persisted catppuccin `localStorage["documenter-theme"]` by deleting the key and re-running `set_theme_from_local_storage()` |

## General rules that keep the whole thing working

- **Never write an unguarded chrome rule.** Every rule that is not
  var-driven must sit under the light `:not()` scope or the dark
  `html.theme--documenter-dark` scope, or it leaks into the catppuccin
  themes.
- **Mirror specificity, then add `html:root`.** The theme's scoped rules
  are `html.theme--<name> <selector>`; prefixing the same selector with
  `html:root` ties them, and your sheet loads after theirs, so order
  resolves the tie. Where the theme adds a class you do not, add
  `#documenter` to win outright.
- **Variables the plugin defines directly** (`--landing-accent`, per-theme
  surfaces) need the `:root`-variant selectors to outrank the plugin's
  later-loaded sheet. Variables it never defines directly (the name and
  glow `-default` chain) are won by definition.
- **Verify against the stock hexes.** After the recolor, scan every page in
  both themes for `#1abc9c`, `#2e63b8`, `#5e6d6f`, `#dbdbdb`. The day one of
  them comes back is the day a Documenter update shipped a new themed
  surface; add it to this inventory in the same change.
