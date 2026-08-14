using Test
using Documenter
using DocumenterLandingPage
using DocumenterCodeBlocks

const DLP = DocumenterLandingPage

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

    @testset "docsite build" begin
        docsite = joinpath(@__DIR__, "docsite")
        include(joinpath(docsite, "make.jl"))

        build = joinpath(docsite, "build")
        index = read(joinpath(build, "index.html"), String)
        rawpage = read(joinpath(build, "raw", "index.html"), String)
        codepage = read(joinpath(build, "code", "index.html"), String)

        @testset "landing page rendered from frontmatter" begin
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
            # Root-relative frontmatter links become page-relative hrefs.
            @test occursin("href=\"tutorial/\"", index)
            @test occursin("href=\"api/\"", index)
            @test occursin("href=\"client\"", index)
            # External URLs pass through unchanged.
            @test occursin("href=\"https://github.com/EnzymeAD/ReactantServer.jl\"", index)
            # The hero image resolves through the assets/ remap.
            @test occursin("src=\"assets/logo.svg\"", index)
            # The frontmatter itself is gone.
            @test !occursin("layout: home", index)
            @test !occursin("---", index)
        end

        @testset "stylesheets injected on every page" begin
            @test occursin("assets/documenterlandingpage/landing.css", index)
            @test occursin("assets/documenterlandingpage/landing.css", rawpage)
        end

        @testset "non-landing @raw blocks pass through" begin
            @test occursin("custom-note", rawpage)
            @test occursin("hand-written HTML, untouched by the plugin", rawpage)
        end

        @testset "DocumenterCodeBlocks still processes code blocks" begin
            @test occursin("line-numbers", codepage)
        end
    end
end
