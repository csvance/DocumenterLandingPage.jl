module DocumenterLandingPage

import Documenter
import Documenter.Selectors
import Documenter.Expanders
import Documenter.Builder
import YAML

export LandingPage

"""
    LandingPage()

Documenter plugin that renders a VitePress-style landing page (hero and emoji
feature tiles) from the YAML frontmatter block a page carries in a `@raw html`
directive:

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
link per tile). The plugin intercepts only `@raw html` blocks whose content is
such frontmatter (`layout: home`) and replaces them with the rendered hero and
tiles; every other `@raw` block passes through to Documenter unchanged. The
YAML stays the single source of truth for the landing copy.

Styling is theme-adaptive: the plugin bundles a stylesheet that defines CSS
custom properties mirroring Documenter's own SCSS palette per shipped theme
(light, dark, and the four catppuccin flavors), so the landing page follows
the visitor's theme (OS preference on first visit, the theme picker
afterwards) with no custom palette of its own. The landing components
consume only those variables.

Pass to `makedocs(plugins = [LandingPage()])`.
"""
struct LandingPage <: Documenter.Plugin end

include("expander.jl")
include("assets.jl")

end # module DocumenterLandingPage
