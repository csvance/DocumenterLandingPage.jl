# Build the docsite with base Documenter only: `plugins = [LandingPage()]`, no
# DocumenterCodeBlocks. Run as a subprocess from test/runtests.jl so the
# process has never loaded DocumenterCodeBlocks: Documenter registers every
# loaded pipeline step for every build, so an in-process build would pick up
# CodeBlocks' asset step regardless of the plugins list, and the
# "no CodeBlocks assets leak" assertion would be vacuous.
#
# Usage: julia --project=<package root> build_base.jl <docsite dir>
using Documenter
using DocumenterLandingPage

root = abspath(ARGS[1])
rm(joinpath(root, "build-base"); recursive = true, force = true)

makedocs(
    root = root,
    build = "build-base",
    sitename = "DocumenterLandingPage.jl",
    doctest = false,
    remotes = nothing,
    format = Documenter.HTML(edit_link = nothing, repolink = nothing, inventory_version = "0.1.0"),
    plugins = [LandingPage()],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Code blocks" => "code.md",
        "Raw passthrough" => "raw.md",
        "API" => "api.md",
    ],
)
