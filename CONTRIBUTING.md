# Contributing

Thanks for considering a contribution. This file covers the local setup, the
workflows CI runs, and the conventions the project expects. It is short on
purpose; the source tree is small and most of it you can read directly.

## Setup

Clone the repository and instantiate the package environment:

```julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

The package runs on Julia 1.10 (the floor in `Project.toml`) and the current
release. Tests are the entry point to confirm your environment works:

```julia
julia --project=. -e 'using Pkg; Pkg.test()'
```

The test suite builds the `test/docsite` fixture twice: once with both
plugins (`LandingPage` plus `CodeBlocks`) and once with base Documenter only
in a subprocess that must never load DocumenterCodeBlocks. The 79 tests
should pass.

## Runic formatting

This repository is formatted with [Runic](https://github.com/fredrikekre/Runic.jl).
Every `.jl` file must be Runic-formatted; CI's `format.yml` fails the build
otherwise. Install the `runic` CLI once (requires Julia 1.12 or newer):

```julia
julia -e 'using Pkg; Pkg.Apps.add("Runic")'
```

### Recommended: install the pre-commit hook

The repository ships a pre-commit hook at `scripts/pre-commit-runic` that
formats `src` and `docs` with Runic and re-stages the result, so your commit
carries formatted code. It skips gracefully (it does not block the commit) if
`runic` is not installed.

Install it locally. The hook is machine-local and not versioned, so this is
per clone:

```bash
cp scripts/pre-commit-runic .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

With the hook in place you can commit as usual; Runic runs automatically and
re-stages any `.jl` files it rewrites. Without the hook, format the source
yourself before committing, either the whole tree or just the source dirs:

```bash
runic --inplace .
# or, to mirror the hook exactly:
runic --inplace src docs
```

Either way, the commit must be Runic-clean for CI to pass.

## Docs

The plugin's documentation lives in `docs/` and dogfoods the landing page:
`docs/src/index.md` carries the very frontmatter the plugin renders, so
building the docs is also a live test of the plugin. Build them locally with:

```bash
cd docs && julia --project=. make.jl
```

The docs environment has its own `Project.toml` and a gitignored `Manifest.toml`;
DocumenterLandingPage resolves from the `docs/Project.toml` `[sources]` path
(the repository root). `docs/make.jl` wires the pages and deploys to GitHub
Pages on `main` and on tags.

## What CI runs

Three workflows gate the repository:

- **CI** (`CI.yml`): runs the 79 tests on Julia 1.10 and 1.12, gated to code,
  test, asset, and Project.toml changes.
- **Format** (`format.yml`): checks that every `.jl` file is Runic-formatted,
  using `fredrikekre/runic-action` pinned to Runic 1.7 (keep your local `runic`
  in sync with that version).
- **Docs** (`Documenter.yml`): builds the docs and deploys to GitHub Pages on
  `main` and on tags; PR builds land on a preview URL via
  `deploydocs(push_preview = true)`.

## Conventions

- **No em dashes or en dashes** in prose, including docs and commit messages.
  Restructure with commas, colons, or shorter sentences.
- **Runic-formatted Julia** everywhere.
- **Reasoning in commit messages**: say why a change was made, not just what
  it does.
- **Plain-English landing tiles**: the feature tiles render as plain escaped
  text with no code formatting, so tile copy must avoid code tokens (see
  `docs/src/frontmatter.md`).

## Getting changes in

1. Make your change on a branch off `main`.
2. Ensure `runic --check .` passes and `julia --project=. -e 'using Pkg;
   Pkg.test()'` is green.
3. If you touched the docs, rebuild them locally to confirm they render.
4. Open a pull request against `main`.

The maintainers review changes; tests, formatting, and docs checks must all
pass before merge.
