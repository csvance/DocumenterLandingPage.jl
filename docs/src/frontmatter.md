# Frontmatter reference

The landing page is driven entirely by the YAML frontmatter block a page
carries in a `@raw html` directive. This page is the authoritative reference
for that schema: every key, what it does, which parts are optional, and how
the plugin renders it. It mirrors the VitePress home layout.

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
  - icon: ⚡                   # emoji shown at the top of the tile
    title: A capability       # tile heading
    details: One sentence.    # tile body (plain text)
    link: /page               # optional: makes the whole tile a link
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
: Optional. An emoji shown above the tile title. Defaults to empty.

`title`
: Optional. The tile heading. Defaults to empty.

`details`
: Optional. The tile body. Rendered as plain escaped text with no markdown or
  code formatting, so tile copy must be written as plain English. Defaults to
  empty.

`link`
: Optional. When present, the whole tile becomes a link to the resolved
  destination. When absent, the tile renders as a plain, non-interactive
  block. See [Link resolution](#Link-resolution).

## Conditional rendering

Only the parts present in the YAML are emitted, so the page adapts to what
you write:

- no `hero.image` (or an empty `src`): no image column;
- no `hero.actions` (or an empty list): no button row;
- a feature without `link`: a plain tile;
- a `hero` subkey that is empty: that element is omitted.

The frontmatter block itself stays byte-for-byte as written in your source;
only its rendering is replaced by the hero and tiles. YAML is the single
source of truth for the landing copy.

## Link resolution

Every `link` (and image `src`) goes through the same resolver. A target is
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
