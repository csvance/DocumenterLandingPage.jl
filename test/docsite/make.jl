using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks

makedocs(
    sitename = "DocumenterLandingPage.jl",
    # Make the docsite build correctly both standalone and when included from
    # test/runtests.jl, whatever the caller's working directory.
    root = @__DIR__,
    doctest = false,
    # The docsite is a test fixture; its git repo has no remote, so disable
    # remote-based edit links and the navbar repository link.
    remotes = nothing,
    # The fixture's custom stylesheet exercises the plugin's opt-in gradient
    # knobs (see src/assets/custom.css); it rides Documenter's own asset
    # machinery like any user stylesheet would.
    format = Documenter.HTML(
        edit_link = nothing,
        repolink = nothing,
        inventory_version = "0.1.0",
        assets = ["assets/custom.css"],
    ),
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
