# DocumenterLandingPage skills

Agent skills for building and theming Documenter.jl documentation sites that
use this plugin. They are **public and self-contained**: each states its
facts in full rather than pointing at a design document, and none references
infrastructure outside this repository. The plugin's own `docs/src/styling.md`
is the reference for the shipped gradient defaults; the skills build on it
and cite it where the detail matters.

| Skill | Use it when |
| --- | --- |
| `dlp-theme` | building a custom theme for a Documenter.jl site with DocumenterLandingPage: brand gradient name, hero glow, and a full recolor of Documenter's chrome (sidebar, navbar, headings, code, docstrings, settings modal) across the light and dark themes |

## Installing

### Pi

Pi discovers skills from `~/.pi/agent/skills/`, a project `.pi/skills/`, and
the `skills` array in `settings.json`. Pick one:

**Per project** (recommended), point pi at this repository's `skills/`
directory from the docs project's `.pi/settings.json`:

```json
{
  "skills": ["/absolute/path/to/DocumenterLandingPage.jl/skills"]
}
```

**Global**, symlink the skill into the agent skills directory:

```bash
ln -s /path/to/DocumenterLandingPage.jl/skills/dlp-theme ~/.pi/agent/skills/
```

**One run**, load it explicitly:

```bash
pi --skill /path/to/DocumenterLandingPage.jl/skills/dlp-theme "theme my docs"
```

### Claude Code

This repository is a Claude Code plugin marketplace. From a Claude Code
session:

```
/plugin marketplace add csvance/DocumenterLandingPage.jl
/plugin install documenterlandingpage-jl
```

The plugin's skills (this `skills/` directory) then load automatically; the
manifest lives in `.claude-plugin/`.

After install, ask for it: "give the docs a burnt-orange theme", "custom
gradients for the landing page", "theme the docs to match the brand".

## Keeping them true

**A skill that teaches a surface has to version with it.** These live in
this repository so that a change to the plugin's stylesheet or to
Documenter's chrome appears in the same diff as the skill that teaches it.
When you change `assets/landing.css` or the plugin's theming behavior, grep
`skills/` before you open the pull request.

The `dlp-theme` skill's `references/chrome-inventory.md` is a working
checklist: when Documenter ships a new themed surface (a new modal, a new
component), the inventory is where it gets added, with the exact selector
and the specificity note that keeps the user stylesheet winning.
