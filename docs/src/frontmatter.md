# Frontmatter reference

The landing page is driven entirely by the YAML frontmatter block a page
carries in a `@raw html` directive. This page is the authoritative reference
for that schema: every key, what it does, which parts are optional, and how
the plugin renders it. It mirrors the VitePress home layout.

Styling is not part of the frontmatter: colors and gradients come from the
plugin's shipped stylesheet through CSS custom properties, and there are no
frontmatter keys for them. See [Styling: gradients and themes](styling.md)
for the gradient defaults, how they tie into Documenter's themes, and how to
customize them.

The complete shape, with every optional part included:

````markdown
```@raw html
---
layout: home

hero:
  name: MyPackage.jl          # the name shown above the headline
  text: A short headline      # the large title
  tagline: One sentence.      # the subtitle under the title
  actions:
    - theme: brand            # "brand" or "alt"
      text: Get started       # button label
      link: /tutorial/        # button destination
  image:
    src: /logo.svg            # primary image (light themes)
    alt: MyPackage.jl         # accessibility text
    dark: /logo-dark.svg      # optional variant for dark themes

features:
  - icon: ⚡                   # emoji shown in the tile's badge box
    title: A capability       # tile heading
    details: One sentence.    # tile body (inline Markdown)
    link: /page               # optional: makes the whole tile a link
  - icon:
      src: /icon.svg          # or an image icon from src/assets/
      alt: Package icon       #   accessibility text
      wrap: true              #   optional: show it in the badge box
    title: Another capability
    details: One sentence.
---
```
````

The plugin claims a block only when its content starts with `---` and contains
`layout: home`. Everything else in a `@raw` block passes through to Documenter
unchanged.

## Top level

`layout`
: Must be `home`. This is the key that makes the block a landing page. Without
  it, the plugin ignores the block entirely.

`hero`
: Optional. A mapping with the hero content. If omitted, the hero header
  renders with whatever subkeys are present (or stays empty if there are
  none).

`features`
: Optional. A list of feature tiles. If omitted or empty, no features section
  renders.

## `hero`

`name`
: Optional. Shown as a small line above the title. Omitted if empty.

`text`
: Optional. Rendered as the large title (`<h1>`). Omitted if empty.

`tagline`
: Optional. Rendered as the subtitle under the title. Omitted if empty.

`actions`
: Optional. A list of buttons. If omitted or empty, no button row renders. See
  [Actions](#Actions).

`image`
: Optional. A mapping for the hero image. If `image` is absent, or its `src`
  is empty, no image column renders. See [Image](#Image).

## Actions

Each entry in `hero.actions` is a button with three keys:

`theme`
: Optional. `"brand"` for the primary button, `"alt"` for the secondary.
  Anything other than `"brand"` is rendered as `alt`. Defaults to `"alt"`.

`text`
: Optional. The button label. Defaults to an empty label.

`link`
: Optional. The button destination, resolved as described in [Link
  resolution](#Link-resolution). Defaults to `#`.

## Image

`src`
: The image file. Required for the image column to render. Resolved as
  described in [Link resolution](#Link-resolution).

`alt`
: Optional. Accessibility text for the image. Defaults to empty.

`dark`
: Optional. A second image shown on dark themes. When present, the plugin
  emits both variants with Documenter's shipped `.docs-light-only` and
  `.docs-dark-only` classes; every theme stylesheet compiles so that light
  themes show `src` and dark themes show `dark`. This is the same mechanism
  Documenter's sidebar logo uses. When `dark` is omitted, a single image is
  emitted for all themes.

The hero image renders at a fixed 320 by 320 size.

## Features

Each entry in `features` is one tile with four keys:

`icon`
: Optional. An emoji (or any text) shown in a small badge box above the tile
  title — or an image, for a real graphic instead of an emoji. Defaults to
  empty. See [Icons](#Icons).

`title`
: Optional. The tile heading. Defaults to empty.

`details`
: Optional. The tile body, rendered as **inline Markdown**: code spans,
  emphasis, links, images, and hard line breaks carry through, while plain
  text stays escaped exactly as it always was. Links resolve through the same
  rules as every other frontmatter link. Defaults to empty. See
  [Markup in details](#Markup-in-details).

`link`
: Optional. When present, the whole tile becomes a link to the resolved
  destination. When absent, the tile renders as a plain, non-interactive
  block. See [Link resolution](#Link-resolution).

## Icons

`icon` accepts two forms, mirroring VitePress's `FeatureIcon`:

**A string** — rendered as escaped text in the 48 by 48 badge box. An emoji is
the normal case:

````markdown
```@raw html
features:
  - icon: ⚡
    title: A capability
    details: One sentence.
```
````

**A mapping** — an image icon (SVG, PNG, ...). The image file goes in
`src/assets/` exactly like the hero image, and is referenced root-relative;
the path resolves through the same [Link resolution](#Link-resolution) rules.

`src`
: The image file. When present, it is used even if `light`/`dark` are also
  given.

`light` / `dark`
: Per-theme image variants, used when `src` is absent. The plugin emits each
  present variant with Documenter's shipped `.docs-light-only` /
  `.docs-dark-only` classes, so every theme shows its own image — the same
  mechanism the hero's [`image.dark`](#Image) uses.

`alt`
: Optional. Accessibility text for the image. Defaults to empty.

`width` / `height`
: Optional. The image's intrinsic size, emitted as `width`/`height`
  attributes. Both default to 48; give real images their actual dimensions.

`wrap`
: Optional. Boolean, defaulting to `false`. When `true`, the image renders
  inside the same badge box a string icon uses, capped at 80% of the box so
  even a square icon keeps some breathing room; when `false` (the default),
  the image renders directly above the tile title with no badge.

A mapping with none of `src`, `light`, or `dark` renders no icon markup at
all:

````markdown
```@raw html
features:
  - icon:
      src: /icon.svg
      alt: Package icon
    title: An image icon
    details: One sentence.
  - icon:
      light: /icon-light.svg
      dark: /icon-dark.svg
      wrap: true
    title: Wrapped, per theme
    details: One sentence.
```
````

## Markup in details

A feature's `details` renders as inline Markdown, so tile copy can carry
code spans, emphasis, links, and images:

````markdown
```@raw html
features:
  - icon: ⚡
    title: A capability
    details: Calls `foo(x)` from **any** package — see the [tutorial](/tutorial/)
      and the [API](api/).
```
````

The rules:

- Plain text is escaped exactly like it always was; raw HTML (`<br>`,
  `<span>`, ...) renders literally and cannot be injected. The Markdown
  parser leaves inline HTML inside text nodes, so it never passes through
  unescaped.
- Links and images resolve through the same
  [link resolution](#Link-resolution) rules as every other frontmatter
  target: `/tutorial/` resolves like a tile `link`, and `/logo.svg` remaps
  into the site's `assets/` directory.
- A line ending in a backslash renders a hard line break (`<br>`).
- Block-level Markdown has no honest inline rendering: a fenced code block
  collapses to an inline code span, and any other block construct (a header,
  a list, ...) makes the whole field fall back to plain escaped text.
- A tile that sets `link` wraps everything in an anchor, and HTML forbids
  nesting anchors. Keep Markdown links to tiles without a tile-level `link`.

Titles, the hero text, and button labels stay plain text, matching VitePress.

## Conditional rendering

Only the parts present in the YAML are emitted, so the page adapts to what
you write:

- no `hero.image` (or an empty `src`): no image column;
- no `hero.actions` (or an empty list): no button row;
- a feature without `link`: a plain tile;
- a feature `icon` mapping without `src`/`light`/`dark`: no icon markup;
- a `hero` subkey that is empty: that element is omitted.

The frontmatter block itself stays byte-for-byte as written in your source;
only its rendering is replaced by the hero and tiles. YAML is the single
source of truth for the landing copy.

## Link resolution

Every `link` — including Markdown links inside `details` — and every image
`src` (Markdown images included) goes through the same resolver. A target is
handled by the first rule that matches:

- empty: returned unchanged;
- starts with `#`: a fragment, returned unchanged. Documenter heading ids are
  Title Case, so reference a heading like `#Usage`, not `#usage`;
- starts with `http://`, `https://`, or `mailto:`: an external target,
  returned unchanged;
- starts with `/`: a root-relative path. If the remaining path names a file
  under your `src/assets/`, it is remapped into the built site's `assets/`
  directory (mirroring Documenter's own copy of that tree). Otherwise it is
  treated as a site page and resolved relative to the current page. A target
  ending in `/` keeps its trailing slash so browsers hit the directory
  directly instead of taking a redirect hop;
- anything else: already relative to the page, returned unchanged.

## YAML gotchas

Because the plugin parses with YAML.jl, a couple of quoting rules bite when
writing frontmatter:

- A plain scalar cannot contain the mapping indicator `": "`. A tagline or
  detail like `Runs in 60s: yes` must be rephrased or quoted.
- A value that starts with `#` must be quoted, otherwise YAML reads it as a
  comment and the key parses as `nothing`. An action pointing at the Usage
  section must be written `link: "#Usage"`, not `link: #Usage`.
- Markdown in `details` follows the same rules. A value that *starts* with a
  link (`[text](/page/) ...`) must be quoted, because YAML reads a leading
  `[` as a flow sequence; and copy containing `": "` (say, a link followed
  by a colon and a space) must be quoted like any other plain scalar.
