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
- `test/runtests.jl` - 70 tests: frontmatter detection, escaping, the docsite
  fixture built with BOTH plugins (LandingPage + CodeBlocks), and a second
  clean-room build with base Documenter only (subprocess, so
  DocumenterCodeBlocks is never loaded; landing markup asserted byte-identical
  and no CodeBlocks assets leak in).
- `test/docsite/` - a test fixture site (landing page with the real
  ReactantServer frontmatter, stub pages, a raw-passthrough fixture, a
  code-block fixture, and `build_base.jl`, the clean-room build script).
- `docs/` - the plugin's own docs, dogfooding the landing page. Hosting is
  `csvance`, not EnzymeAD (docs/make.jl already points at
  `github.com/csvance/DocumenterLandingPage.jl`).
- `README.md` - the compatibility story (base Documenter lead, code-block
  composition, usage, frontmatter shape, compat pins).
- `.github/workflows/` - CI.yml (tests on Julia 1.10 + 1.12),
  format.yml (runic check via fredrikekre/runic-action v1.7), Documenter.yml
  (docs build + deploydocs to gh-pages, push_preview on PRs), and TagBot.yml
  (tags releases from JuliaRegistrator notifications).
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
- `julia --project=. -e 'using Pkg; Pkg.test()'` passes (70/70).

## Resolved bug: trailing slashes on resolved links (fixed)

Previously the resolver lost the frontmatter's trailing slashes on most
landing links (`href="tutorial"`, `href="api"` for `/api/`, ...) while the
`assets/` remap kept working. Root cause: `_resolve_href` decided everything
from the **build-tree filesystem state** (`isdir`/`isfile` under
`doc.user.build`), but the expander runs during ExpandTemplates (~order 2.0),
when page output directories (`build/tutorial/`) do not exist yet; they are
created in RenderDocument at 6.0. Only copied assets exist at that point
(SetupBuildDirectory, order 1.0, copies non-md files), which is why
`build/assets/logo.svg` was found and every page slash was dropped. The
handoff's earlier observation that `api/` kept its slash in the real docs was
stale-build noise: Documenter does not clean `build/` unless `clean = true`,
so a previous run's `build/api/` made `isdir` true; the clean docsite build
lost every slash.

Fix (in `src/generate.jl`, debug line removed): the resolver no longer
consults the build tree. A target ending in `/` is a directory page and keeps
its trailing slash (VitePress semantics); the `assets/` remap is decided from
the source tree (`isfile(joinpath(doc.user.root, doc.user.source, "assets",
t))`), which always exists at expand time; and both sides of the `relpath`
are anchored at `doc.user.root` so the result does not depend on the process
working directory. Verified on a clean docsite build and on the real
ReactantServer docs build: every landing link keeps its frontmatter slash
and `src="assets/logo.svg"` still resolves.

## Compatibility hardening (done, plus one optional)

1. DONE: a second build in the tests, `test/docsite/build_base.jl`, runs the
   docsite fixture with `plugins = [LandingPage()]` only, as a **subprocess**
   so DocumenterCodeBlocks is never loaded in that process (Documenter
   registers every loaded pipeline step for every build, so an in-process
   build would pick up CodeBlocks' asset step regardless of the plugins list).
   The test asserts the landing markup is byte-identical to the both-plugins
   build and that no CodeBlocks assets leak in.
2. DONE: the main docsite testset is now named "both plugins compose
   (LandingPage + CodeBlocks)" and asserts both plugins' assets on the same
   pages plus the CodeBlocks output.
3. DONE: `README.md` written with the compatibility story as the lead.
4. DONE: GitHub Actions workflows, mirroring the ReactantServer conventions
   (pinned action SHAs, concurrency groups, commented permissions): CI.yml
   tests on Julia 1.10 (LTS compat floor) and 1.12; format.yml runs
   fredrikekre/runic-action@v1 with runic 1.7; Documenter.yml builds the
   docs on every push/PR and deploys via deploydocs to the gh-pages branch
   on main and tags (`push_preview = true` needs the repo's Pages source set
   to the gh-pages branch); TagBot.yml tags releases from JuliaRegistrator
   notifications (needs the DOCUMENTER_KEY secret for signed tags).

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
