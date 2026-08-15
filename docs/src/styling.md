# Styling: gradients and themes

The landing page is styled entirely with CSS: its colors and gradients come
from the plugin's shipped stylesheet (`assets/landing.css`) through CSS
custom properties, and there are **no frontmatter keys** for styling. The
frontmatter drives the *content* (hero copy, image, tiles); everything about
*how it looks* is CSS. This page is the reference for the gradient defaults,
how they tie into Documenter's themes, and how to implement your own.

## Shipped defaults

Two gradient effects ship on by default, both derived from the theme's own
accent color so the hero follows the visitor's theme:

**Gradient package name** — opaque, applied only where the browser supports
`background-clip: text` (with a solid accent fallback elsewhere):

```css
--landing-name-color-default: transparent;
--landing-name-background-default: linear-gradient(120deg, <accent>, <hue+35°> 50%, <hue+70°>);
```

**Glow behind the logo** — a translucent disc, blurred into a halo that
spills over the page background:

```css
--landing-glow-default: linear-gradient(-45deg, <accent> 50%, <hue+60°> 50%);
--landing-glow-filter: blur(40px);   /* the disc's filter, settable too */
```

The glow stops carry ~0.5 alpha in every theme. The same translucent stops
read stronger on dark themes: the dark background preserves the accent's
chroma, while on light themes the background washes the halo toward white.
The name gradient is deliberately fully opaque: it paints *through* the
glyphs, so translucency would just fade the name into the page.

### Per-theme defaults

Every one of Documenter's six shipped themes carries its own derived pair.
`documenter-light` is the `:root` default; the other five live under the
same `html.theme--<name>` selectors the palette uses. The values below are
transcribed from `assets/landing.css`:

| Theme | Accent | Name gradient (opaque) | Glow gradient (alpha) |
|---|---|---|---|
| `documenter-light` (`:root`) | `#2e63b8` | `#2e63b8, #6d51b0 50%, #92418e` | `#2e63b880 50%, #89459980 50%` |
| `documenter-dark` | `#1abc9c` | `#1abc9c, #00b7ce 50%, #51aaee` | `#1abc9c80 50%, #38aee780 50%` |
| `catppuccin-latte` | `#1e66f5` | `#1e66f5, #8646e4 50%, #b927ad` | `#1e66f580 50%, #ad30c080 50%` |
| `catppuccin-frappe` | `#8caaee` | `#8caaee, #b69ce3 50%, #d592c5` | `#8caaee80 50%, #ce94cf80 50%` |
| `catppuccin-macchiato` | `#8aadf4` | `#8aadf4, #b79eea 50%, #d893cb` | `#8aadf480 50%, #d096d680 50%` |
| `catppuccin-mocha` | `#89b4fa` | `#89b4fa, #b8a5f3 50%, #db99d5` | `#89b4fa80 50%, #d39cdf80 50%` |

### Why the stops look the way they do

The stops are the accent rotated along the **OKLCH hue wheel** (~+35° and
~+70° for the name, ~+60° for the glow), every stop held at about the
accent's own chroma (clamped to the sRGB gamut). Two consequences:

- **Hue rotation, not guessing.** Rotating the theme's accent guarantees
  every stop reads as "the same color, shifted" in every theme, and the
  middle stop sits on the hue arc between the endpoints.
- **Chroma held, so no gray-dip.** Browsers interpolate CSS gradients in
  sRGB by default, where distant hues blend through desaturated gray in the
  middle (purple → red's midpoint is a muted mauve). Holding the stops at
  the endpoints' chroma — including an explicit saturated middle stop —
  keeps the whole blend colorful.

The defaults deliberately do **not** use `in oklab` / `in oklch` gradient
interpolation: engines that support `var()` but not oklab (Chrome 105–110,
Firefox 110–112, Safari 16.0–16.1) reject the value at computed-value time,
the background becomes `none`, and a gradient-clipped name turns invisible.
Explicit saturated stops work everywhere. Follow the same rule in your own
stylesheets.

## How this ties into Documenter's themes

- The plugin's stylesheet defines CSS custom properties that **mirror
  Documenter's own SCSS palette** per shipped theme (`$link` → `--landing-accent`,
  `$background` → `--landing-surface`, and so on), transcribed into the
  `:root` + five `html.theme--<name>` blocks. If Documenter ever changes a
  theme color, only that small variable block in `assets/landing.css` needs
  updating.
- The landing components consume **only those custom properties** — no
  theme-specific rules of their own — so the hero follows whatever theme is
  active (OS preference on first visit, the theme picker afterwards),
  including the four catppuccin flavors.
- The `html.theme--<name>` selectors carry the same specificity as
  Documenter's own theme stylesheets, so the landing's defaults resolve
  under the same conditions the theme itself does.
- **User overrides win regardless of stylesheet load order.** The shipped
  rules chain the user's variable over the shipped default — e.g.
  `background: var(--landing-glow, var(--landing-glow-default))` — and the
  plugin's sheet is injected *after* user `assets=` stylesheets
  (`src/assets.jl`), so your `--landing-*` definitions are the only ones
  that exist. This is the same contract VitePress's `--vp-home-hero-*`
  variables provide.

## Your own gradients

Four variables control the gradient effects. Declare them in your own
stylesheet and pass it to `makedocs` via `assets=` (or add them to any
stylesheet you already load).

### The gradient package name

Set **both** name variables together — the color unhides the clipped
gradient fill, the background paints it:

```css
:root {
    --landing-name-color: transparent;
    --landing-name-background: linear-gradient(120deg, #9558b2 30%, #b8418f 65%, #cb3c33);
}
```

- Setting only `--landing-name-background` paints the gradient fine (the
  shipped default color is already `transparent`, so the clipped fill
  unhides on its own). The traps are the one-sided *restorations*:
  setting `--landing-name-background: none` without also setting
  `--landing-name-color: currentcolor` leaves a transparent fill with no
  background — an invisible name — and setting a gradient background while
  leaving a non-transparent fill hides the gradient behind the solid
  glyphs. Change the pair together.
- Put an explicit saturated stop on the hue arc between your endpoints
  (the middle-stop rule above) — the Lux.jl dark theme lists a middle color
  for exactly this reason.
- To restore the plain solid-accent name:

```css
:root {
    --landing-name-color: currentcolor;
    --landing-name-background: none;
}
```

### The glow

`--landing-glow` accepts any `background` value; `--landing-glow-filter`
defaults to `blur(40px)`:

```css
:root {
    --landing-glow: linear-gradient(-45deg, #9558b2 50%, #cb3c33 50%);
    --landing-glow-filter: blur(40px);   /* or e.g. blur(56px) for a softer spread */
}
```

- The **alpha on the stops is the softness dial**: opaque stops with a hard
  split give VitePress's canonical `-45deg, #bd34fe 50%, #47caff 50%` look;
  translucent stops (like the shipped defaults) read softer over the page.
- Keep the two stops **near-analogous** (the accent and a hue neighbor) so
  the blurred seam stays saturated. Alpha blending to the page background
  does not create the gray-dip — that is a property of *gradient
  interpolation between distant hues*, handled by the middle-stop rule.

### Per-theme overrides

Give a theme its own stops through the same selectors the plugin's palette
uses — any of `html.theme--documenter-light`, `html.theme--documenter-dark`,
`html.theme--catppuccin-latte`, `-frappe`, `-macchiato`, `-mocha`:

```css
html.theme--documenter-dark {
    --landing-name-background: linear-gradient(120deg, #9558b2 15%, #4063d8 52%, #389826 90%);
    --landing-glow: linear-gradient(-45deg, #389826 50%, #4063d8 50%);
    --landing-glow-filter: blur(56px);
}
```

### Graceful degradation

The shipped sheet guards the gradient name so it never breaks on older or
specialized environments: the clipped gradient applies only inside
`@supports ((-webkit-background-clip: text) or (background-clip: text))`
(browsers without it keep the solid accent fill), `forced-colors` (Windows
High Contrast) and `print` media restore the solid fill, and `::selection`
gets an explicit visible pair. Keep these guards in mind when writing your
own name gradients — in particular, do not rely on `in oklab` /
`in oklch` interpolation, which newer engines reject outright (see above).
