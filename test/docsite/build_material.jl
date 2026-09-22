# Build the docsite with MaterialDocs' `Material3` writer instead of
# Documenter's own HTML writer, with `plugins = [LandingPage()]` and nothing
# else. Run as a subprocess from test/runtests.jl, for the same reason
# build_base.jl is: Documenter registers every loaded pipeline step for every
# build, so a build in a process that has also loaded DocumenterCodeBlocks
# would pick up its asset step regardless of the plugins list.
#
# Loading MaterialDocs here is also what activates
# DocumenterLandingPageMaterialDocsExt, which is the thing under test.
#
# Usage: julia --project=<env with MaterialDocs> build_material.jl <docsite dir>
using Documenter
using DocumenterLandingPage
using MaterialDocs

root = abspath(ARGS[1])
rm(joinpath(root, "build-material"); recursive = true, force = true)

makedocs(
    root = root,
    build = "build-material",
    sitename = "DocumenterLandingPage.jl",
    doctest = false,
    remotes = nothing,
    # `dark_mode = :toggle` exercises every branch of the light/dark image
    # swap: MaterialDocs then emits no `data-theme` on <html> and lets the
    # visitor set one, so both the media-query and the attribute rules in
    # landing-material.css are live on the same page.
    format = Material3(
        edit_link = nothing,
        repolink = nothing,
        dark_mode = :toggle,
        inventory_version = "0.1.0",
        assets = ["assets/custom.css"],
    ),
    plugins = [LandingPage()],
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Code blocks" => "code.md",
        "Raw passthrough" => "raw.md",
        "API" => "api.md",
    ],
)
