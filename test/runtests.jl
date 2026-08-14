using Test
using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks

const DLP = DocumenterLandingPage

# The landing page markup is the plugin's contract: whatever the surrounding
# build (base Documenter alone, or composed with DocumenterCodeBlocks), the
# rendered hero + tiles must be identical. This helper asserts the full
# rendered landing against the real ReactantServer frontmatter used by the
# docsite fixture.
function _assert_landing(index::AbstractString)
    @test occursin("id=\"landing\"", index)
    # All six feature tiles, in order, with their emoji icons.
    @test count("class=\"landing-feature\"", index) == 6
    for emoji in ["⚡", "🚀", "🧩", "💾", "🔀", "🔁"]
        @test occursin(emoji, index)
    end
    for title in [
            "KServe V2, natively", "XLA under the hood", "Julia-first",
            "On-demand weights", "A coalescing scheduler", "Hot reload",
        ]
        @test occursin(title, index)
    end
    @test occursin("landing-name\">ReactantServer.jl", index)
    @test occursin("landing-title\">Production inference", index)
    @test occursin("landing-btn--brand", index)
    # Root-relative frontmatter links become page-relative hrefs, keeping the
    # frontmatter's trailing slash on directory targets.
    @test occursin("href=\"tutorial/\"", index)
    @test occursin("href=\"api/\"", index)
    @test occursin("href=\"client/\"", index)
    @test occursin("href=\"on_demand_weights/\"", index)
    # External URLs pass through unchanged.
    @test occursin("href=\"https://github.com/EnzymeAD/ReactantServer.jl\"", index)
    # The hero image resolves through the assets/ remap.
    @test occursin("src=\"assets/logo.svg\"", index)
    # The frontmatter itself is gone.
    @test !occursin("layout: home", index)
    return @test !occursin("---", index)
end

# The landing div spans from its opening tag to the features section's closing
# tag; the prose below the landing ("What it is") follows immediately after.
const LANDING_REGION = r"(?s)<div id=\"landing\".*?</section>\n</div>"

@testset "DocumenterLandingPage" begin

    @testset "frontmatter detection" begin
        @test DLP._is_landing_frontmatter("---\nlayout: home\n---")
        @test DLP._is_landing_frontmatter("---\nlayout: home\n\nhero:\n  name: X\nfeatures: []\n---")
        @test DLP._is_landing_frontmatter("---\n# a comment\nlayout: home\n---")
        @test !DLP._is_landing_frontmatter("---\nlayout: docs\n---")
        @test !DLP._is_landing_frontmatter("<div>plain html, not frontmatter</div>")
        @test !DLP._is_landing_frontmatter("")
    end

    @testset "escaping" begin
        @test DLP._esc("a & b") == "a &amp; b"
        @test DLP._esc("<a href=\"x\">") == "&lt;a href=&quot;x&quot;&gt;"
        @test DLP._esc("plain text") == "plain text"
    end

    @testset "theme-aware hero image" begin
        # `image.dark` emits both logo variants with Documenter's own
        # light/dark classes (every shipped theme stylesheet compiles one of
        # them to `display: none`, so exactly one image shows per theme);
        # without it, a single image is emitted.
        docsite = joinpath(@__DIR__, "docsite")
        doc = (user = (root = docsite, source = "src", build = "build"),)
        page = (build = "build/index.html",)
        base = Dict{Any, Any}(
            "layout" => "home",
            "hero" => Dict{Any, Any}(
                "name" => "X",
                "image" => Dict{Any, Any}(
                    "src" => "/logo.svg", "alt" => "Logo", "dark" => "/logo-dark.svg",
                ),
            ),
            "features" => Any[],
        )
        html = DLP._render_landing(base, doc, page)
        @test occursin("class=\"docs-light-only\"", html)
        @test occursin("class=\"docs-dark-only\"", html)
        # The light variant resolves through the assets/ remap; the dark one
        # is not in the docsite's src/assets, so it resolves as a page href.
        @test occursin("src=\"assets/logo.svg\"", html)
        @test occursin("src=\"logo-dark.svg\"", html)
        @test count("<img ", html) == 2

        # Without `dark`, the hero carries a single image, unchanged.
        single = deepcopy(base)
        delete!(single["hero"]["image"], "dark")
        html2 = DLP._render_landing(single, doc, page)
        @test !occursin("docs-light-only", html2)
        @test !occursin("docs-dark-only", html2)
        @test count("<img ", html2) == 1
        @test occursin("src=\"assets/logo.svg\"", html2)
    end

    @testset "both plugins compose (LandingPage + CodeBlocks)" begin
        # The docsite fixture is built with both plugins in one makedocs call:
        # this is the compatibility test that the landing page and the enhanced
        # code blocks coexist in a single build.
        docsite = joinpath(@__DIR__, "docsite")
        include(joinpath(docsite, "make.jl"))

        build = joinpath(docsite, "build")
        index = read(joinpath(build, "index.html"), String)
        rawpage = read(joinpath(build, "raw", "index.html"), String)
        codepage = read(joinpath(build, "code", "index.html"), String)

        @testset "landing page rendered from frontmatter" begin
            _assert_landing(index)
        end

        @testset "stylesheets injected on every page" begin
            # Both plugins' assets ride Documenter's own asset machinery.
            @test occursin("assets/documenterlandingpage/landing.css", index)
            @test occursin("assets/documenterlandingpage/landing.css", rawpage)
            @test occursin("assets/documentercodeblocks/line-numbers.css", index)
        end

        @testset "non-landing @raw blocks pass through" begin
            @test occursin("custom-note", rawpage)
            @test occursin("hand-written HTML, untouched by the plugin", rawpage)
        end

        @testset "DocumenterCodeBlocks still processes code blocks" begin
            @test occursin("line-numbers", codepage)
        end
    end

    @testset "base Documenter compatibility (LandingPage alone)" begin
        # The same landing frontmatter, built with base Documenter only: no
        # DocumenterCodeBlocks in the plugins list. The landing must render
        # identically, and no CodeBlocks assets may leak into the build.
        #
        # The build runs in a fresh subprocess that has never loaded
        # DocumenterCodeBlocks: Documenter registers every loaded pipeline
        # step for every build, so an in-process build would pick up CodeBlocks'
        # asset step regardless of the plugins list and the no-leak assertion
        # would be vacuous. This mirrors a user who depends only on this
        # plugin.
        docsite = joinpath(@__DIR__, "docsite")
        base_build = joinpath(docsite, "build-base")
        rm(base_build; recursive = true, force = true)
        script = joinpath(docsite, "build_base.jl")
        run(`$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) $script $docsite`)
        try
            base_index = read(joinpath(base_build, "index.html"), String)
            both_index = read(joinpath(docsite, "build", "index.html"), String)

            _assert_landing(base_index)
            # Byte-identical landing markup in both builds.
            base_landing = match(LANDING_REGION, base_index)
            both_landing = match(LANDING_REGION, both_index)
            @test base_landing !== nothing
            @test both_landing !== nothing
            @test base_landing.match == both_landing.match
            # The plugin's own stylesheet is still injected...
            @test occursin("assets/documenterlandingpage/landing.css", base_index)
            # ...and no DocumenterCodeBlocks assets leak into a build that
            # does not use that plugin.
            @test !occursin("documentercodeblocks", base_index)
        finally
            rm(base_build; recursive = true, force = true)
        end
    end
end
