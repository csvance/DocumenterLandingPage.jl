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
        "Frontmatter reference" => "frontmatter.md",
        "API Reference" => "api.md",
    ],
)

Documenter.deploydocs(
    repo = "github.com/csvance/DocumenterLandingPage.jl.git",
    push_preview = true,
    devbranch = "main",
)
