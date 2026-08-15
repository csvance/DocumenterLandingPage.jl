# DocumenterLandingPage.jl

[![Docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://csvance.github.io/DocumenterLandingPage.jl/dev/)
[![Tests](https://img.shields.io/github/actions/workflow/status/csvance/DocumenterLandingPage.jl/CI.yml?branch=main&label=Tests)](https://github.com/csvance/DocumenterLandingPage.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Julia 1.12](https://img.shields.io/badge/Julia-1.12-9558b2)](https://julialang.org)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

A Documenter plugin that renders a VitePress-style landing page (hero and
feature tiles with emoji or image icons) from the YAML frontmatter block a
page carries in a `@raw html` directive.

## Compatibility first

The plugin works with **base Documenter.jl**: the stock `Documenter.HTML`
format, no VitePress, no Node, no custom theme, and no `assets=` entries in
your `makedocs` call. The theme picker, OS-based default theme, search, and
all stock Documenter chrome are untouched; the landing page adapts to
whatever theme is active (light, dark, and the four catppuccin flavors).

It also composes with [DocumenterCodeBlocks.jl](https://github.com/fredrikekre/DocumenterCodeBlocks.jl):
both run in one build, the plugin's CSS is injected through the same asset
mechanism CodeBlocks uses, and the landing page and enhanced code blocks
coexist on the same pages.

## Usage

```julia
using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks  # optional, for enhanced code blocks

makedocs(
    sitename = "MyPackage.jl",
    format = Documenter.HTML(),
    plugins = [
        LandingPage(),
        CodeBlocks(),  # optional
    ],
)
```

That is the whole integration. There is no theme to select and nothing to
add to `assets=`; the stylesheet ships with the plugin and is injected
automatically.

## The frontmatter

The landing page is driven by the same YAML home layout VitePress uses, kept
in the `@raw html` block at the top of the page (typically `index.md`):

````markdown
```@raw html
---
layout: home

hero:
  name: MyPackage.jl
  text: A short headline
  tagline: One sentence.
  actions:
    - theme: brand
      text: Tutorial
      link: /tutorial/
    - theme: alt
      text: View on GitHub
      link: https://github.com/MyOrg/MyPackage.jl
  image:
    src: /logo.svg
    alt: MyPackage.jl
    dark: /logo-dark.svg   # optional: a variant for dark themes

features:
  - icon: ⚡
    title: A capability
    details: One sentence about it.
    link: /tutorial/
  - icon: 🚀
    title: Another capability
    details: One sentence about it.
---
```
````

The plugin intercepts `@raw html` blocks whose content is such frontmatter
(`layout: home`) and replaces them with the rendered hero and tiles. Every
other `@raw` block passes through to Documenter unchanged. The YAML stays the
single source of truth for the landing copy; the rendered hero and features
match the VitePress home layout, with root-relative links and images
resolved to page-relative URLs. An optional `image.dark` gives the hero a
second image for dark themes: the plugin emits both variants with
Documenter's own `.docs-light-only`/`.docs-dark-only` classes, which every
shipped theme stylesheet compiles to show one or the other, so a logo with a
light and a dark variant (like Documenter's own) adapts automatically.

## Styling

The landing consumes only CSS custom properties that mirror Documenter's own
SCSS palette per shipped theme, so it follows the visitor's theme with no
custom palette of its own. If Documenter ever changes a theme color, only the
small variable block in `assets/landing.css` needs a one-line update.

### Gradient name and glow

The hero ships with gradients by default: the package name is painted in a
gradient derived from the theme's own accent color, and the logo sits on the
VitePress-style glow. The name gradient is opaque — the accent and two
hue-rotated neighbors (~+35° and ~+70° on the OKLCH hue wheel), every stop
held at about the accent's own chroma so the blend never passes through the
desaturated gray that plain sRGB gradient interpolation produces between
distant hues. The glow is translucent — the accent and its ~+60° hue
neighbor split hard, with a 40px blur as the transition, at ~0.5 alpha in
the light themes and ~0.6 in the dark ones, so the halo reads soft over the
page background while staying present on dark. Each of Documenter's six
themes carries its own derived pair (through the same `html.theme--<name>`
selectors the palette uses, mirroring Documenter's own SCSS palette), so the
hero follows the visitor's theme just like the rest of the landing.

Everything is overridable with the same variables VitePress exposes for its
hero (`--vp-home-hero-name-*` and `--vp-home-hero-image-*` there,
`--landing-*` here) — declare them in your own stylesheet (passed to
`makedocs` via `assets=`) and they win regardless of stylesheet load order.
For example, the Lux.jl name gradient in the Julia colors:

```css
:root {
    /* Set both name variables together: the color unhides the gradient, the
     * background paints it. The middle stop matters: browsers interpolate
     * gradients in sRGB, where distant hues blend through desaturated grays
     * — purple straight to red dips to a muted mauve in the middle. A stop
     * on the hue arc between the two, at about the endpoints' own chroma,
     * keeps the whole name saturated (this is why the Lux.jl dark theme
     * lists a middle color). */
    --landing-name-color: transparent;
    --landing-name-background: linear-gradient(120deg, #9558b2 30%, #b8418f 65%, #cb3c33);

    /* The glow disc accepts any `background` value. The alpha on the stops
     * is the softness dial: opaque stops with a hard split and the blur as
     * the transition give VitePress's canonical `-45deg, #bd34fe 50%,
     * #47caff 50%` look, while translucent stops (like the shipped
     * defaults) read softer over the page. Keep the two stops
     * near-analogous so the blurred seam stays saturated. */
    --landing-glow: linear-gradient(-45deg, #9558b2 50%, #cb3c33 50%);
    --landing-glow-filter: blur(40px); /* default */
}

/* Dark themes get their own stops through the same selectors the plugin's
 * palette uses (any of: html.theme--documenter-light, html.theme--
 * documenter-dark, html.theme--catppuccin-latte, -frappe, -macchiato,
 * -mocha). Three saturated Julia brand colors — the blue middle stop keeps
 * the purple -> green blend from passing through gray. */
html.theme--documenter-dark {
    --landing-name-background: linear-gradient(120deg, #9558b2 15%, #4063d8 52%, #389826 90%);
    --landing-glow: linear-gradient(-45deg, #389826 50%, #4063d8 50%);
    --landing-glow-filter: blur(56px);
}
```

To restore the plain solid-accent package name:

```css
:root {
    --landing-name-color: currentcolor;
    --landing-name-background: none;
}
```

The gradient name degrades gracefully: browsers without `background-clip:
text` keep the solid accent fill, forced-colors (Windows High Contrast) and
print media restore it, and selecting the text stays readable.

See [Styling: gradients and themes](docs/src/styling.md) for the full
per-theme default table and the complete customization reference.

## Compatibility

- Documenter 1.17
- YAML 0.4
- Julia 1.10 (LTS and newer)

## License

MIT
