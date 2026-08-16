---
name: dlp-theme
description: >
  Build a custom theme for a Documenter.jl docs site that uses the
  DocumenterLandingPage plugin: brand gradient package name, hero glow, and a
  full recolor of Documenter's chrome (sidebar, navbar, headings, links, code
  blocks, docstrings, settings modal, theme picker) across the light and dark
  themes, shipped from the site's own assets= stylesheet with no changes to
  Documenter or the plugin. Invoke when asked to theme, rebrand, or add custom
  gradients to a DocumenterLandingPage docs site, or when a site's landing
  page or chrome still shows stock Documenter colors after a partial recolor.
---

# Custom Documenter themes with DocumenterLandingPage

The landing page (hero, name gradient, glow, tiles, buttons) is styled
entirely by CSS custom properties in the plugin's `assets/landing.css`; the
rest of the site (sidebar, navbar, headings, code, docstrings, settings
modal) is styled by Documenter's shipped theme CSS. You recolor both with
one of your own stylesheets, passed to `makedocs` via `assets=`. No changes
to Documenter or the plugin are needed.

This skill is the working knowledge from building a full burnt-brown and
gold theme on a real site, including the places where the cascade silently
fights you. Start from the template and the inventory; the traps section
explains every fight.

## The two-layer model

**Landing layer.** The plugin's sheet defines CSS custom properties that
mirror Documenter's palette per theme (`:root` for light, five
`html.theme--<name>` blocks for dark and the four catppuccin flavors). The
landing components consume only those properties. The plugin's sheet is
injected *after* your `assets=` stylesheets, and the consumer rules chain
your variable over the shipped default, e.g.
`background: var(--landing-glow, var(--landing-glow-default))`. So for the
variables the plugin never defines directly, your definition is the only
one and always wins.

**Chrome layer.** Documenter's theme CSS (the huge minified files in
`build/assets/themes/`) hardcodes colors. The light file is unscoped; the
dark and catppuccin files scope every rule under `html.theme--<name>`. Your
stylesheet loads after the theme sheets, so at equal specificity you win by
order; the theme wins when its selector is more specific. Mirror the
theme's selectors and prefix with `html:root` to beat it.

## Wiring (the only Julia change)

In `docs/make.jl`, inside `Documenter.HTML(...)`:

```julia
assets = ["assets/brand.css", "assets/brand.js"],
```

Files live in `docs/src/assets/` (the `assets=` paths are relative to the
source dir). Documenter copies them into `build/assets/` and links them in
the head of every page. `.css` becomes a stylesheet link; `.js` becomes a
script tag (used for runtime fixes like pruning the theme picker).

Then rebuild with the site's own build command:

```bash
julia --project=docs docs/make.jl
```

## The override contract

Landing variables you can own (the plugin's `docs/src/styling.md` is the
authoritative reference for defaults and shapes):

- `--landing-name-color` + `--landing-name-background`: the package name.
  Set them together. The color unhides the clipped gradient fill, the
  background paints it. The gradient must be opaque; keep an explicit
  saturated middle stop (sRGB interpolation between distant hues dips
  through gray), and do not use `in oklab`/`in oklch` interpolation, which
  some engines reject and which turns the clipped name invisible.
- `--landing-glow`: any `background` value for the disc behind the logo.
  The alpha on the stops is the softness dial; the shipped defaults use
  ~0.5 alpha with `blur(40px)` via `--landing-glow-filter`. Keep the two
  stops near-analogous.
- `--landing-accent`: the brand button, tile hover border, selection.
- `--landing-surface`, `--landing-surface-2`, `--landing-border`: the tile
  surfaces.

Chrome variables: none exist; you define your own `--brand-*` palette (see
the template) and one set of consumer rules that read them. Undefined
`var(--brand-x, fallback)` declarations no-op, which is how your rules stay
out of the catppuccin themes: define the palette only under your light and
dark scopes, and the consumers harmlessly fall back everywhere else.

## Scoping: the rules that decide which theme gets which colors

1. **The default light theme has no class.** Documenter's themeswap sets
   `html.className = ""` for the default light (OS light, nothing picked).
   It sets `theme--documenter-light` only when the user explicitly picks it.
   So "light" is two states, and a `html.theme--documenter-light` selector
   matches neither of them on first visit.
2. **Dark and catppuccin are class-scoped.** `html.theme--documenter-dark`
   and `html.theme--catppuccin-*`.
3. The robust light scope, covering both light states and excluding dark
   plus every catppuccin class:

   ```css
   html:root:not(.theme--documenter-dark):not([class*="theme--catppuccin"])
   ```

   and the dark scope:

   ```css
   html.theme--documenter-dark          /* rules */
   html.theme--documenter-dark:root     /* variables the plugin defines
                                           directly, e.g. --landing-accent */
   ```

4. If you leave the catppuccin themes alone (the plugin ships them in the
   picker), every non-variable rule must be guarded by the `:not()` scope or
   it will apply under catppuccin too.

## The traps: where the cascade fights you

These are the specific defeats, in the order they cost time:

1. **Light scoping** (above). A `html.theme--documenter-light` override
   silently never matches on first visit.
2. **`--landing-accent` is defined directly by the plugin** (unlike the
   name/glow vars, which ship only as `-default` variants). Same specificity
   plus the plugin's later load order means the plugin wins. Outrank it with
   the `:root` variants above. The name and glow variables need no such
   trick: the plugin never defines them directly, so yours are the only
   definitions.
3. **The theme paints every nav row.** `#documenter .docs-sidebar
   ul.docs-menu .tocitem` gets the default page background. Set the rows
   transparent so the sidebar's own background shows, then paint the active
   block yourself.
4. **`li.is-active` beats a generic `li` rule.** The theme's
   `... ul.docs-menu li.is-active` (background plus top/bottom borders) has
   higher specificity than `... ul.docs-menu li`. Target `li.is-active`
   directly for both background and borders, or the stock color shows as
   strips at the active block's edges.
5. **`.content pre` outranks `pre`.** Code blocks get a 2px stock border
   from the theme's `.content pre` rule. Pin `html:root .content pre` too.
6. **Docstrings are heavily stock.** `details.docstring` boxes carry a 2px
   stock border; the `> summary` bar uses the stock surface and a stock
   border; `> section` has a stock border; the source-link tags
   (`a.docs-sourcelink`) are painted with the theme accent; the
   `summary::before` chevron is the accent blue. All need explicit rules
   (specificities up to `html.theme--x details.docstring>section>
   a.docs-sourcelink.is-link:not(body)`; beat them with the `#documenter`
   prefix).
7. **Line-number gutters load after your CSS.** DocumenterCodeBlocks ships
   `--ln-*` tokens in its own sheets, linked after your assets. Override
   them at higher specificity (`html.theme--documenter-dark:root`),
   matching `--ln-bg` to your code block background. The JuliaSyntax token
   palette (`--jl-*`) is a separate, self-contained palette; leave it or
   override it the same way.
8. **The header does not reach the sides.** The sidebar is 18rem while the
   content column starts at a 20rem margin (plus 1rem right padding), so
   strips of page background show beside the header. The stock theme hides
   this because all its surfaces are one color. Fix with negative margins
   and compensating padding on `header.docs-navbar`:

   ```css
   margin-left: -2rem; margin-right: -1rem;
   padding-left: 2rem;  padding-right: 1rem;
   ```

9. **The theme picker offers four catppuccin themes.** If your site ships
   its own light and dark themes only, remove the catppuccin `<option>`s
   from `#documenter-themepicker` with a small `brand.js`, and reset a
   persisted catppuccin `localStorage["documenter-theme"]` by re-running
   `set_theme_from_local_storage()` after deleting the key. Run the option
   removal on `DOMContentLoaded`: the picker lives in the settings modal at
   the end of the body, and a head script runs before it exists.
10. **Gradient luminance flips per theme.** A bright start (amber, gold)
    vanishes on a light page; a dark end (burnt brown) vanishes on a dark
    page. Give light and dark themes different ramps that both stay in
    readable mid-tones, and verify contrast on each.
11. **Structure borders need their own color.** Recoloring sidebar
    structure borders to a tone near the sidebar background makes them
    invisible; use a dedicated, clearly contrasting divider color.

## The workflow

1. Copy the template to `docs/src/assets/brand.css` and set the palette
   variables (two blocks: light and dark).
2. Wire `assets=` in `make.jl`.
3. Rebuild and open `docs/build/index.html`.
4. Verify in both themes, including the pages that exercise the edges: the
   API page (docstrings, source links, admonitions), a content page (code
   blocks, headings, tables), a narrow viewport (sidebar hidden, header
   full-bleed), and the settings modal (theme picker).
5. Pixel-verify (see below) that no stock colors survive: the dark accent
   `#1abc9c`, the light accent `#2e63b8`, the dark border `#5e6d6f`, the
   light border `#dbdbdb`.

## Verification (headless + pixels)

Screenshot both themes headlessly. Dark needs the theme forced: a Firefox
profile with `user_pref("ui.systemUsesDarkTheme", 1);` in `user.js` makes
Documenter's OS-preference fallback pick the dark theme. (A wrapper page
that sets `localStorage` then redirects does not survive the screenshot;
patch a copy of `themeswap.js` or use the profile.)

Then scan the screenshots:

- **No stock colors**: count pixels within a tolerance of the four stock
  hexes above on every page and theme. Zero (a handful of antialiasing
  pixels is noise).
- **Name gradient renders**: sample the name line left to right; the hue
  must sweep (e.g. burnt 17 deg to amber 29 deg on light) and the fill must
  be opaque (large distance from the page background).
- **Glow is soft**: a radial profile of the halo should be a smooth bell
  peaking around 40% of the name's strength, with low saturation on light
  (the same ~0.5 alpha reads stronger on dark by design).
- **Contrast**: the light name ramp must clear roughly 3:1 on light, the
  dark ramp on dark; this is what forces per-theme ramps.
- **Chrome**: headings, links, code block backgrounds, docstring boxes, and
  the sidebar structure lines all render in the palette, none in stock
  colors.

The template ships with the consumer-rule structure that makes all of this
verifiable: one palette per theme scope, one set of `html:root`-prefixed
consumers, nothing unguarded.

## Reference material

- `references/chrome-inventory.md`: the exhaustive selector checklist for
  Documenter's chrome, with the exact rule to add and the specificity note.
- `assets/brand.css.template`: the starting theme (palette blocks plus the
  consumer-rule skeleton), filled in with a working example palette.
- The plugin's `docs/src/styling.md`: the shipped gradient defaults and the
  full override contract, cited above where the detail matters.
- `assets/landing.css` in this repository: the source of truth for the
  landing variables and their per-theme defaults.
