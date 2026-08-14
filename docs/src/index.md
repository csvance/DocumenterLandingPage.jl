```@raw html
---
layout: home

hero:
  name: DocumenterLandingPage.jl
  text: A VitePress-style landing page for Documenter.jl
  tagline: Render a hero and emoji feature tiles from YAML frontmatter, theme-adaptive across all of Documenter's shipped themes.
  actions:
    - theme: brand
      text: Get started
      link: /api/
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
    details: The same VitePress home frontmatter, hero, actions, and feature tiles with emoji icons, all unchanged.
  - icon: 🎨
    title: Theme-adaptive
    details: Colors mirror Documenter's own SCSS palette per theme, so the landing follows light, dark, and every catppuccin flavor.
  - icon: 🧩
    title: A Documenter plugin
    details: Pass plugins = [LandingPage()] to makedocs; the CSS is injected automatically, no assets= entries.
  - icon: 🤝
    title: DocumenterCodeBlocks, together
    details: Run makedocs(plugins = [LandingPage(), CodeBlocks()]) and both work in one build, the landing page and enhanced code blocks, with no conflicts.
  - icon: 🪶
    title: Drop-in
    details: index.md keeps its @raw html frontmatter block byte-for-byte; nothing else in your docs changes.
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
