```@raw html
---
layout: home

hero:
  name: DocumenterLandingPage.jl
  text: A VitePress-style landing page for Documenter.jl
  tagline: Render a hero and feature tiles with emoji or image icons from YAML frontmatter, theme-adaptive across all of Documenter's shipped themes.
  actions:
    - theme: brand
      text: Get started
      link: /tutorial/
    - theme: alt
      text: View on GitHub
      link: https://github.com/csvance/DocumenterLandingPage.jl
  image:
    src: /logo.svg
    alt: DocumenterLandingPage.jl

features:
  - icon: 📄
    title: YAML frontmatter
    details: The exact VitePress home layout — hero, actions, and feature tiles with emoji or image icons — all from one `@raw html` block. See the [frontmatter reference](/frontmatter/).
  - icon: 🎨
    title: Theme-adaptive
    details: Mirrors Documenter's own theme palette, so the landing follows light, dark, and every catppuccin flavor, customizable through [CSS variables](/styling/).
  - icon:
      light: /documenter-logo.svg
      dark: /documenter-logo-dark.svg
      alt: Documenter.jl
      wrap: true
    title: Documenter plugin
    details: Add `plugins = [LandingPage()]` to your `makedocs` call, and the stylesheet is injected automatically, no assets to configure.
    link: /tutorial/
  - icon: 🤝
    title: CodeBlocks-ready
    details: Pair it with `DocumenterCodeBlocks`, and both run in one build without conflicts.
  - icon: 🪶
    title: Drop-in
    details: Your frontmatter block stays **byte-for-byte** as written; only its rendering is replaced by the hero and tiles.
    link: /frontmatter/
  - icon: ⚙️
    title: No toolchain
    details: No VitePress, no Node, no custom theme — just base Documenter and a YAML block.
  - icon: 📝
    title: Markup in details
    details: Tile copy renders **inline Markdown** — `code spans`, [internal links](/tutorial/), [external links](https://commonmark.org), and *emphasis* — with links resolving through the same rules as tile links.
---
```

## What it is

This page is rendered by the plugin itself: the hero and the tiles above come
from the YAML frontmatter in the `@raw html` block at the top of `index.md`,
and the tiles' details show off the plugin's inline Markdown — code spans,
links, and emphasis. See [Markup in details](frontmatter.md#Markup-in-details)
for the full rules. Tiles with a `link` are clickable end to end — try the
[plugin](tutorial/), [drop-in](frontmatter/), and repository tiles — while
the tiles that keep their links in the copy render as plain blocks.

## Usage

Add the package and pass the plugin to `makedocs`:

```julia
using Documenter, DocumenterLandingPage, DocumenterCodeBlocks

makedocs(
    sitename = "MyPackage",
    format = Documenter.HTML(),
    plugins = [LandingPage(), CodeBlocks()],
)
```

See the [API reference](api.md) for the plugin's documentation.

See [Styling: gradients and themes](styling.md) for how the landing's
default gradients work with Documenter's themes and how to customize them.
