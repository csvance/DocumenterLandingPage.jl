module DocumenterLandingPage

import Documenter
import Documenter.Selectors
import Documenter.Expanders
import Documenter.Builder
import YAML

export LandingPage

"""
    LandingPage()

Documenter plugin that renders a VitePress-style landing page (hero and
feature tiles with emoji or image icons) from the YAML frontmatter block a
page carries in a `@raw html` directive:

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
      link: /tutorial
  image:
    src: /logo.svg
    alt: MyPackage.jl
    dark: /logo-dark.svg   # optional: a variant for dark themes

features:
  - icon: ⚡
    title: A capability
    details: One sentence about it.
    link: /page
---
```
````

The frontmatter is exactly the VitePress home layout: a `hero` block (name,
text, tagline, actions, image) and a `features` block (icon, title, details,
link per tile). A tile's icon may be an emoji string or an image mapping
(`src`, or `light`/`dark` theme variants, with an optional badge `wrap`).
An optional `image.dark` gives the hero a second image for
dark themes: the plugin emits both variants with Documenter's own
`.docs-light-only`/`.docs-dark-only` classes, which every shipped theme
stylesheet compiles to show one or the other (the same mechanism
Documenter's sidebar logo uses). The plugin intercepts only `@raw html`
blocks whose content is
such frontmatter (`layout: home`) and replaces them with the rendered hero and
tiles; every other `@raw` block passes through to Documenter unchanged. The
YAML stays the single source of truth for the landing copy.

Styling is theme-adaptive: the plugin bundles a stylesheet that defines CSS
custom properties mirroring Documenter's own SCSS palette per shipped theme
(light, dark, and the four catppuccin flavors), so the landing page follows
the visitor's theme (OS preference on first visit, the theme picker
afterwards) with no custom palette of its own. The landing components
consume only those variables.

Gradient styling ships on by default, derived from each theme's accent: an
opaque gradient package name and a translucent accent-hue glow behind the
logo, with per-theme defaults for all six themes. Everything is overridable
through CSS custom properties declared in your own `assets=` stylesheet,
which wins regardless of load order: `--landing-name-color` and
`--landing-name-background` (set them together) for the name,
`--landing-glow` and `--landing-glow-filter` for the glow. See the
[styling reference](styling.md) for the per-theme defaults and the complete
customization guide.

Pass to `makedocs(plugins = [LandingPage()])`.
"""
struct LandingPage <: Documenter.Plugin end

include("generate.jl")
include("expander.jl")
include("assets.jl")

end # module DocumenterLandingPage
