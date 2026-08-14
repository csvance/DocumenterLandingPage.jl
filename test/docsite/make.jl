using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks

makedocs(
    sitename = "DocumenterLandingPage.jl",
    doctest = false,
    # The docsite is a test fixture; its git repo has no remote, so disable
    # remote-based edit links.
    remotes = nothing,
    format = Documenter.HTML(inventory_version = "0.1.0"),
    plugins = [
        LandingPage(),
        CodeBlocks(),
    ],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Code blocks" => "code.md",
        "Raw passthrough" => "raw.md",
        "API" => "api.md",
    ],
)
