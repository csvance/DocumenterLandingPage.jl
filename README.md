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

## Compatibility

- Documenter 1.17
- YAML 0.4
- Julia 1.10 (LTS and newer)

## License

MIT
