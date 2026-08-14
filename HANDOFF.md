# HANDOFF: DocumenterLandingPage.jl

Written for the next agent to continue this work directly in this repo.
Read this first, then the plan in `/home/csvance/Git/ReactantServer.jl/PLAN.md`
for the full context (this repo is one deliverable of that plan).

## Mission

`DocumenterLandingPage.jl` is a small Documenter plugin that renders a
VitePress-style landing page (hero + emoji feature tiles) from the YAML
frontmatter block a page carries in a `@raw html` directive. It exists so the
ReactantServer.jl docs can move off DocumenterVitepress onto the stock
Documenter HTML theme while keeping the current landing page, with the
`index.md` frontmatter unchanged.

**The compatibility story is the point of the project, and it should stay the
framing for every decision here:**

- The plugin works with **base Documenter.jl**: stock `Documenter.HTML`
  format, no VitePress, no Node, no custom theme, no `assets=` entries in the
  user's `makedocs` call. The theme picker, OS-based default theme, search,
  versions.js, and all stock chrome are untouched; the landing page adapts to
  whatever theme is active.
- The plugin composes with **DocumenterCodeBlocks.jl**:
  `makedocs(plugins = [LandingPage(), CodeBlocks()])`. Both run in one build;
  the plugin's CSS is injected through the same asset mechanism CodeBlocks
  uses, and the landing page and enhanced code blocks coexist.

## Repo map

- `src/DocumenterLandingPage.jl` - module, `LandingPage <: Documenter.Plugin`
  struct, docstring (this is also the only public API).
- `src/generate.jl` - YAML -> HTML rendering and href resolution.
- `src/expander.jl` - the `@raw html` interception (the only Documenter hook
  that renders the landing page).
- `src/assets.jl` - the asset-injection pipeline step.
- `assets/landing.css` - the bundled stylesheet (theme-adaptive CSS custom
  properties mirroring Documenter's SCSS palette for all six shipped themes).
- `test/runtests.jl` - 38 tests: frontmatter detection, escaping, and a
  docsite build with content assertions.
- `test/docsite/` - a test fixture site (landing page with the real
  ReactantServer frontmatter, stub pages, a raw-passthrough fixture, and a
  code-block fixture) built with both plugins.
- `docs/` - the plugin's own docs, dogfooding the landing page. Hosting is
  `csvance`, not EnzymeAD (docs/make.jl already points at
  `github.com/csvance/DocumenterLandingPage.jl`).
- `HANDOFF.md` - this file.

## Current state (all verified)

- Expander intercepts `@raw html` blocks whose content is frontmatter with
  `layout: home` (order 10.5, before Documenter's RawBlocks at 11.0); every
  other `@raw` block passes through untouched (proved by the raw.md fixture).
- YAML.jl parses the frontmatter (delimiters and emoji handled natively).
- The generated HTML matches the VitePress home structure; links/images
  resolve root-relative frontmatter paths to page-relative hrefs, with a bare
  filename -> `assets/` remap so `/logo.svg` finds `assets/logo.svg`.
- Asset step (order 5.5) copies `assets/landing.css` into
  `build/assets/documenterlandingpage/` and pushes it into the HTML format's
  assets; the link tag appears on every page with correct relative paths.
- Theme-adaptive styling verified in Playwright for documenter-light,
  documenter-dark, and catppuccin-mocha: coherent surfaces (tiles one step
  above the page background, badges one more), accent-colored name and brand
  button, hero at 1064px and tiles at ~338px (the 72rem widening beats the
  theme's own rules by matching their `html.theme--<name>` specificity).
- The real ReactantServer docs build with the plugin: landing renders, prose
  below renders, search and theme picker work, the Tutorial button navigates,
  and DocumenterCodeBlocks processes the code blocks (its build warnings about
  a few docstrings are informational, not failures).
- `julia --project=. -e 'using Pkg; Pkg.test()'` passes (38/38).

## Open bug: inconsistent trailing slashes on resolved links

Symptom (real docs build, `build/index.html`):

```
<a class="landing-btn landing-btn--brand" href="tutorial">   <- no slash
<a class="landing-btn landing-btn--alt" href="api/">         <- slash
<a class="landing-feature" href="client"                     <- no slash
...all six tiles: no slash
```

The frontmatter has `link: /tutorial/`, `/api/`, `/client/`, ... all with
trailing slashes. Only `api/` keeps it. `src="assets/logo.svg"` resolves
correctly. Both behaviors come from `_resolve_href` in `src/generate.jl`.

Working hypothesis: `_resolve_href` decides the trailing slash (and the
assets remap) from the **build-tree filesystem state** (`isdir`/`isfile` under
`doc.user.build`), but the expander runs during ExpandTemplates (~order 2.0),
when page output directories (`build/tutorial/`) do not exist yet (they are
created in RenderDocument at 6.0); only copied assets exist at that point.
That explains `assets/logo.svg` working, and most links losing the slash. It
does NOT explain why `api/` keeps its slash, so there is a real discrepancy
to pin down before fixing. Possible contributing factor: `doc.user.build` is
a relative path, so the checks depend on the process working directory at
expand time, which may differ between pages.

A debug print was added to `_resolve_href` (uncommitted, in `src/generate.jl`)
to settle this. Run a docsite build with debug logging:

```
cd test/docsite
JULIA_DEBUG=DocumenterLandingPage julia --project=. make.jl
```

and inspect the `resolve` lines (target, pwd(), doc.user.build, resolved,
isdir, href) for `tutorial` vs `api`. Then remove the debug line.

Likely fix direction: do not consult the build tree at expand time. VitePress
semantics are enough: a frontmatter target ending in `/` is a directory page,
one without is a file/asset. Preserve the frontmatter's trailing slash
whenever the target ends with `/`; decide the `assets/` remap from the
**source** tree (`docs/src/assets/...`) or by the absence of a trailing slash
on a non-external target, not from `isdir` on the build tree.

## Compatibility hardening (recommended next steps)

The current tests prove both plugins in ONE docsite, but do not prove the
plugin works with base Documenter alone. Add:

1. A second docsite variant (or a second `makedocs` call in the tests) built
   with `plugins = [LandingPage()]` only, no DocumenterCodeBlocks, using the
   same landing `index.md`. Assert the landing HTML is identical and that no
   CodeBlocks assets leak in.
2. Assert the existing docsite contains both the landing HTML and CodeBlocks
   output (already partially covered; make it explicit that this is the
   "both plugins" compatibility test).
3. Write the missing `README.md` with the compatibility story as the lead:
   base Documenter compatibility, DocumenterCodeBlocks composition, usage
   (`makedocs(plugins = [LandingPage(), CodeBlocks()])`), the frontmatter
   shape, and the compat pins (Documenter 1.17, YAML 0.4, julia 1.10).
4. Optionally a GitHub Actions workflow for the plugin repo (test on
   julia-actions/setup-julia; the docsite test needs no Node).

## ReactantServer.jl integration state (do not lose this)

In `/home/csvance/Git/ReactantServer.jl` (a separate repo, sibling checkout):

- `docs/Project.toml`: DocumenterVitepress and HTTP removed; DocumenterCodeBlocks
  and DocumenterLandingPage added; `[sources] DocumenterLandingPage =
  {path = "../../DocumenterLandingPage.jl"}` (sibling path, local builds only).
- `docs/make.jl`: `Documenter.HTML` format with both plugins; `index.md`
  frontmatter untouched; footer credits the two plugins under csvance/fredrikekre.
- Deleted: `docs/src/.vitepress/`, `docs/package.json`, `docs/package-lock.json`,
  `docs/node_modules/`; the `npm ci` step is gone from
  `.github/workflows/docs.yml`; CONTRIBUTING.md's docs section rewritten.
- Staged but NOT committed: `docs/Project.toml`, `docs/make.jl`, and the four
  deletions. Unstaged: `.github/workflows/docs.yml`, `CONTRIBUTING.md`,
  `.gitignore` (added `/.scratch/`). The repo has other pre-existing
  uncommitted changes (root Project.toml, README.md, docs/src/index.md,
  manual/tutorial pages, packages/*) that are NOT part of this work; do not
  touch or commit those.
- The docs build works locally because the sibling checkout exists. **CI
  blocker:** `Pkg.instantiate()` in CI cannot resolve a local path; the
  `[sources]` entry must be switched to a git URL
  (`https://github.com/csvance/DocumenterLandingPage.jl`) once this repo has a
  remote. Only the user can push/create the remote; flag it rather than
  guessing.

## Verification toolkit

- Plugin tests: `julia --project=. -e 'using Pkg; Pkg.test()'` from this repo.
- Docsite standalone: `cd test/docsite && julia --project=. make.jl`.
- Real docs: `cd /home/csvance/Git/ReactantServer.jl/docs && julia --project=. make.jl`
  (needs the workspace env instantiated; takes a few minutes).
- Visual checks: Playwright is installed in
  `/home/csvance/Git/ReactantServer.jl/.scratch/proto/` (node_modules +
  `shot_docsite.js` for the docsite, `shot_real.js` for the real docs; it
  screenshots light/dark/catppuccin-mocha and prints computed styles). If the
  sandbox was relaunched, reinstall there with `npm i playwright` and
  `npx playwright install chromium`. Screenshots land as `docsite-*.png` /
  `real-*.png` next to the scripts. The current model cannot view images;
  rely on the printed computed-style JSON for assertions.
- Documenter 1.17.0, DocumenterCodeBlocks 1.3.0, YAML 0.4.x, Julia 1.12.6.
  Documenter's theme SCSS lives under
  `~/.julia/packages/Documenter/AXNMp/assets/html/scss/` (the per-theme CSS
  variables in `assets/landing.css` are transcribed from there).

## Conventions

- Runic.jl formatting for Julia sources (the author's other repos enforce it;
  run `runic --inplace .` before committing if available).
- No em dashes or en dashes in prose; use commas, colons, or restructure.
- Commit messages carry the reasoning, not just the change.
