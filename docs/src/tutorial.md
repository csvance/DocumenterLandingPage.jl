# Tutorial

This page walks through a complete end to end use of DocumenterLandingPage:
add the package, drop a VitePress-style frontmatter block into a page, pass
the plugin to `makedocs`, and watch it render a hero and feature tiles with
emoji or image icons.

## 1. Add the package

Open your documentation environment and add
`DocumenterLandingPage` alongside Documenter. If you also use
DocumenterCodeBlocks, add that too, since both plugins run in the same build:

```julia
using Pkg
Pkg.add("DocumenterLandingPage")
Pkg.add("DocumenterCodeBlocks")
```

The package works with base Documenter and its stock HTML format. There is no
VitePress, no Node, and no custom theme to install.

## 2. Put the frontmatter in a page

The plugin reads a YAML frontmatter block that lives inside a `@raw html`
directive at the top of a page. Add it to your `index.md`:

````markdown
```@raw html
---
layout: home

hero:
  name: MyPackage.jl
  text: A short headline
  tagline: One sentence about what your package does.
  actions:
    - theme: brand
      text: Get started
      link: /tutorial/
    - theme: alt
      text: View on GitHub
      link: https://github.com/you/MyPackage.jl

features:
  - icon: ⚡
    title: A capability
    details: One sentence about it.
  - icon: 🎨
    title: Another capability
    details: One sentence about it.
  - icon: 🧩
    title: A third capability
    details: One sentence about it.
  - icon:
      src: /icon.svg
      alt: Package icon
    title: An image icon
    details: One sentence about it.
---
```
````

The last tile shows the other icon form: an image file from your
`src/assets/` directory, referenced root-relative like any other asset. The
[frontmatter reference](frontmatter.md) covers the full icon options,
including per-theme variants and badge wrapping.

Two things matter here:

- The block must be `@raw html`, and its content must start with `---` and
  contain `layout: home`. That exact combination is what tells the plugin to
  claim the block and replace it with the rendered landing. Any other `@raw`
  block passes through to Documenter unchanged.
- Keep the tile `details` as plain English. The plugin escapes the text and
  does not run markdown or code formatting inside tiles, so save code tokens
  for the surrounding prose.

## 3. Pass the plugin to `makedocs`

Register the plugin in your `docs/make.jl`. The `plugins` list accepts it
alone or alongside DocumenterCodeBlocks:

```julia
using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks

makedocs(
    sitename = "MyPackage.jl",
    format = Documenter.HTML(),
    modules = [MyPackage],
    plugins = [
        LandingPage(),
        CodeBlocks(),
    ],
)
```

Run the build exactly as you normally would:

```julia
julia --project=docs make.jl
```

The stylesheet is injected for you. You do not need to add `assets = [...]`
entries or touch the format config; the plugin registers its CSS in an asset
step that runs before the HTML format writes out the pages.

## 4. See the rendered result

The plugin turns the frontmatter into the hero and feature tile markup. The
`index.html` it produces, trimmed to the essentials, looks like this:

```html
<div id="landing" class="landing">
  <header class="landing-hero">
    <div class="landing-hero__text">
      <p class="landing-name">MyPackage.jl</p>
      <h1 class="landing-title">A short headline</h1>
      <p class="landing-tagline">One sentence about what your package does.</p>
      <div class="landing-actions">
        <a class="landing-btn landing-btn--brand" href="tutorial/">Get started</a>
        <a class="landing-btn landing-btn--alt" href="https://github.com/you/MyPackage.jl">View on GitHub</a>
      </div>
    </div>
  </header>
  <section class="landing-features" aria-label="Features">
    <div class="landing-feature">
      <div class="landing-feature__icon">⚡</div>
      <h2 class="landing-feature__title">A capability</h2>
      <p class="landing-feature__details">One sentence about it.</p>
    </div>
    <div class="landing-feature">
      <img class="landing-feature__icon-img" src="assets/icon.svg" alt="Package icon" width="48" height="48">
      <h2 class="landing-feature__title">An image icon</h2>
      <p class="landing-feature__details">One sentence about it.</p>
    </div>
  </section>
</div>
```

Notice what the resolver did with the links: the external GitHub URL passed
through as written, and the root-relative `/tutorial/` was turned into the
page-relative `tutorial/` that points at the built page. The image icon's
`/icon.svg` was remapped into the site's `assets/` directory, just like a hero
image would be.
The [frontmatter reference](frontmatter.md) explains the exact rules.

The landing follows the visitor's theme automatically: it uses CSS custom
properties that mirror Documenter's own palette for light, dark, and every
catppuccin flavor, so there is nothing more to configure.

That is it. You now have a VitePress-style landing page running on base
Documenter.
