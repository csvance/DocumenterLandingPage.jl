using Documenter
using DocumenterCodeBlocks
using DocumenterLandingPage

makedocs(
    sitename = "DocumenterLandingPage.jl",
    doctest = false,
    format = Documenter.HTML(
        edit_link = "main",
        canonical = "https://csvance.github.io/DocumenterLandingPage.jl/",
        inventory_version = "0.1.0",
        # The site deploys to a GitHub Pages *project* page
        # (…/DocumenterLandingPage.jl/dev/), so favicon hrefs must stay
        # page-relative. Documenter computes that per page for `asset`s, and
        # the `:ico` class is the supported way to emit `<link rel=icon>`
        # from non-`.ico` files. Browsers sniff the served content, so the
        # generic type hint Documenter writes is harmless.
        assets = [
            Documenter.asset("assets/icon.svg", class = :ico, islocal = true),
            Documenter.asset("assets/favicon-32.png", class = :ico, islocal = true),
        ],
    ),
    repo = Documenter.Remotes.GitHub("csvance", "DocumenterLandingPage.jl"),
    modules = [DocumenterLandingPage],
    plugins = [
        LandingPage(),
        CodeBlocks(),
    ],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Styling" => "styling.md",
        "Frontmatter reference" => "frontmatter.md",
        "API Reference" => "api.md",
    ],
)

Documenter.deploydocs(
    repo = "github.com/csvance/DocumenterLandingPage.jl.git",
    push_preview = true,
    devbranch = "main",
)
