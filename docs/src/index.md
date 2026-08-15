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
    dark: /logo-dark.svg

features:
  - icon: 📄
    title: YAML frontmatter
    details: The exact VitePress home layout, with hero, actions, and feature tiles with emoji or image icons, all from one YAML frontmatter block.
  - icon: 🎨
    title: Theme-adaptive
    details: Mirrors Documenter's own theme palette, so the landing follows light, dark, and every catppuccin flavor.
  - icon:
      src: /logo.svg
      alt: DocumenterLandingPage.jl
    title: Documenter plugin
    details: Add it to your plugins list, and the stylesheet is injected automatically, no assets to configure.
  - icon: 🤝
    title: CodeBlocks-ready
    details: Pair it with DocumenterCodeBlocks, and both run in one build without conflicts.
  - icon: 🪶
    title: Drop-in
    details: Your frontmatter block stays byte-for-byte as written; only its rendering is replaced by the hero and tiles.
  - icon: ⚙️
    title: No toolchain
    details: No VitePress, no Node, no custom theme, just base Documenter and a YAML block.
---
```

## What it is

This page is rendered by the plugin itself: the hero and the tiles above come
from the YAML frontmatter in the `@raw html` block at the top of `index.md`.

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
