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
    # All eleven feature tiles, in order: six with emoji icons, one bare image
    # icon, three wrapped image icons (the wide logo plus two 1:1 SVGs), and
    # one exercising inline Markdown in details.
    @test count("class=\"landing-feature\"", index) == 11
    for emoji in ["⚡", "🚀", "🧩", "💾", "🔀", "🔁", "📝"]
        @test occursin(emoji, index)
    end
    # The image-icon tiles render resolved <img>s (assets/ remap, 48x48): the
    # bare one directly as a tile child, the wrapped ones inside the badge box.
    @test occursin(
        "<img class=\"landing-feature__icon-img\" src=\"assets/logo.svg\" alt=\"ReactantServer.jl\" width=\"48\" height=\"48\">",
        index,
    )
    @test occursin(
        "<div class=\"landing-feature__icon\">\n"
            * "<img src=\"assets/logo.svg\" alt=\"ReactantServer.jl\" width=\"48\" height=\"48\">\n"
            * "</div>",
        index,
    )
    # The 1:1 SVG icons are wrapped too, resolved through the assets/ remap.
    @test occursin("<img src=\"assets/icon-chip.svg\" alt=\"Chip icon\" width=\"48\" height=\"48\">", index)
    @test occursin("<img src=\"assets/icon-bolt.svg\" alt=\"Bolt icon\" width=\"48\" height=\"48\">", index)
    for title in [
            "KServe V2, natively", "XLA under the hood", "Julia-first",
            "On-demand weights", "A coalescing scheduler", "Hot reload",
            "Custom tile icons", "A wrapped image icon", "Device agnostic",
            "Low-latency inference", "Markup in details",
        ]
        @test occursin(title, index)
    end
    @test occursin("landing-name\">ReactantServer.jl", index)
    @test occursin("landing-title\">Production inference", index)
    @test occursin("landing-btn--brand", index)
    # Details render as inline Markdown: code spans, emphasis, and links —
    # root-relative targets resolve like every other frontmatter link, and
    # external URLs pass through unchanged.
    @test occursin("Speaks the <code>KServe V2</code> inference API", index)
    @test occursin("<code>model.jl</code>", index)
    @test occursin("<strong>plain Julia</strong>", index)
    @test occursin("<a href=\"raw/\">links to pages</a>", index)
    @test occursin(
        "<a href=\"https://vitepress.dev/reference/default-theme-home-page\">external links</a>",
        index,
    )
    @test occursin("<em>emphasis</em>", index)
    # Root-relative frontmatter links become page-relative hrefs, keeping the
    # frontmatter's trailing slash on directory targets.
    @test occursin("href=\"tutorial/\"", index)
    @test occursin("href=\"api/\"", index)
    @test occursin("href=\"client/\"", index)
    @test occursin("href=\"on_demand_weights/\"", index)
    # External URLs pass through unchanged.
    @test occursin("href=\"https://github.com/EnzymeAD/ReactantServer.jl\"", index)
    # The hero image resolves through the assets/ remap, inside the fixed
    # square container the stylesheet sizes the logo and its glow in.
    @test occursin(
        "<div class=\"landing-hero__image-container\">\n" *
            "      <img src=\"assets/logo.svg\"",
        index,
    )
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

    @testset "image feature icons" begin
        # `icon` accepts VitePress's `FeatureIcon` object forms: an image
        # (`src`), per-theme variants (`light`/`dark`), an optional badge
        # wrap, and explicit width/height (default 48). Icon paths resolve
        # through the same assets/ remap as the hero image, and a string icon
        # (emoji) still renders the badge div byte-for-byte as before.
        docsite = joinpath(@__DIR__, "docsite")
        doc = (user = (root = docsite, source = "src", build = "build"),)
        page = (build = "build/index.html",)
        tile(icon) = DLP._render_feature(merge(Dict{Any, Any}("title" => "T"), Dict{Any, Any}("icon" => icon)), doc, page)

        # A string icon is unchanged: escaped text in the badge div.
        html = tile("⚡")
        @test occursin("<div class=\"landing-feature__icon\">⚡</div>", html)
        # An absent icon still renders the (empty) badge div.
        html = DLP._render_feature(Dict{Any, Any}("title" => "T"), doc, page)
        @test occursin("<div class=\"landing-feature__icon\"></div>", html)

        # `src` renders an image icon directly as a tile child (no badge),
        # resolved through the assets/ remap with 48x48 default sizing.
        html = tile(Dict{Any, Any}("src" => "/logo.svg", "alt" => "Logo"))
        @test occursin(
            "<img class=\"landing-feature__icon-img\" src=\"assets/logo.svg\" alt=\"Logo\" width=\"48\" height=\"48\">",
            html,
        )
        @test !occursin("<div class=\"landing-feature__icon\">", html)

        # `wrap: true` puts the image inside the badge box.
        html = tile(Dict{Any, Any}("src" => "/logo.svg", "alt" => "Logo", "wrap" => true))
        @test occursin(
            "<div class=\"landing-feature__icon\">\n"
                * "<img src=\"assets/logo.svg\" alt=\"Logo\" width=\"48\" height=\"48\">\n"
                * "</div>",
            html,
        )

        # `light`/`dark` emit both variants with Documenter's theme classes.
        html = tile(Dict{Any, Any}("light" => "/logo.svg", "dark" => "/logo-dark.svg", "alt" => "L"))
        @test occursin(
            "<img class=\"docs-light-only landing-feature__icon-img\" src=\"assets/logo.svg\" alt=\"L\" width=\"48\" height=\"48\">",
            html,
        )
        @test occursin(
            "<img class=\"docs-dark-only landing-feature__icon-img\" src=\"logo-dark.svg\" alt=\"L\" width=\"48\" height=\"48\">",
            html,
        )

        # Wrapped variants keep the theme classes but no icon-img class.
        html = tile(Dict{Any, Any}("light" => "/logo.svg", "dark" => "/logo-dark.svg", "wrap" => true))
        @test occursin(
            "<div class=\"landing-feature__icon\">\n"
                * "<img class=\"docs-light-only\" src=\"assets/logo.svg\" alt=\"\" width=\"48\" height=\"48\">\n"
                * "<img class=\"docs-dark-only\" src=\"logo-dark.svg\" alt=\"\" width=\"48\" height=\"48\">\n"
                * "</div>",
            html,
        )

        # Explicit width/height are honored.
        html = tile(Dict{Any, Any}("src" => "/logo.svg", "width" => 64, "height" => 32))
        @test occursin("width=\"64\" height=\"32\"", html)

        # A mapping with no image target emits no icon markup at all.
        html = tile(Dict{Any, Any}("alt" => "x"))
        @test !occursin("<img", html)
        @test !occursin("landing-feature__icon", html)
    end

    @testset "inline markdown in details" begin
        # `details` renders as inline Markdown (issue #5): code spans,
        # emphasis, links, images, and hard line breaks, with every text node
        # still escaped. Links and image sources ride the same resolver as
        # every other frontmatter target, raw HTML never passes through (the
        # stdlib parser leaves it inside text nodes), and block-level
        # constructs collapse: fenced code becomes an inline code span while
        # anything else falls back to the plain escaped text of the whole
        # field, exactly how details rendered before.
        docsite = joinpath(@__DIR__, "docsite")
        doc = (user = (root = docsite, source = "src", build = "build"),)
        page = (build = "build/index.html",)
        function tile(details)
            return DLP._render_feature(
                Dict{Any, Any}("title" => "T", "details" => details), doc, page
            )
        end

        # Plain text round-trips exactly as it always rendered: escaped,
        # with no markup injected.
        @test occursin("<p class=\"landing-feature__details\">a &amp; b &lt; c</p>", tile("a & b < c"))
        @test occursin("<p class=\"landing-feature__details\"></p>", tile(""))

        # Code spans (content escaped) and nested emphasis.
        @test occursin("the <code>KServe V2</code> API", tile("the `KServe V2` API"))
        @test occursin("<code>a &amp; b</code>", tile("`a & b`"))
        @test occursin("<strong>plain <em>very</em> Julia</strong>", tile("**plain *very* Julia**"))

        # Links resolve through the frontmatter rules: root-relative targets
        # keep their trailing slash, external URLs pass through, and images
        # remap bare src/assets/ files into the site's assets/ directory.
        @test occursin("<a href=\"tutorial/\">the tutorial</a>", tile("see [the tutorial](/tutorial/)"))
        @test occursin("<a href=\"https://julialang.org\">Julia</a>", tile("[Julia](https://julialang.org)"))
        @test occursin("<img src=\"assets/logo.svg\" alt=\"the logo\">", tile("![the logo](/logo.svg)"))

        # Hard line breaks (trailing backslash) render <br>.
        @test occursin("one<br>two", tile("one\\\ntwo"))

        # Raw HTML stays escaped: the parser keeps it inside text nodes.
        @test occursin("&lt;br&gt;", tile("a <br> b"))

        # Block-level constructs collapse.
        @test occursin("<code>x = 1</code>", tile("use:\n\n```\nx = 1\n```"))
        # Anything but paragraphs and fenced code falls back to the plain
        # escaped text of the whole field (here: a header followed by a list).
        @test occursin("<p class=\"landing-feature__details\"># H &amp; more</p>", tile("# H & more"))
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
            # Both plugins' assets ride Documenter's own asset machinery, and
            # the fixture's custom stylesheet (exercising the opt-in gradient
            # knobs with the Lux.jl recipe) rides alongside them.
            @test occursin("assets/documenterlandingpage/landing.css", index)
            @test occursin("assets/custom.css", index)
            @test occursin("assets/documenterlandingpage/landing.css", rawpage)
            @test occursin("assets/documentercodeblocks/line-numbers.css", index)
        end

        @testset "shipped stylesheet gradient contract" begin
            # The stylesheet we ship must keep the opt-in machinery intact:
            # the name-gradient feature query with both clip spellings, the
            # fill chained to the opt-in variable, the fallback guards, and
            # the configurable glow filter.
            css = read(joinpath(build, "assets", "documenterlandingpage", "landing.css"), String)
            @test occursin("@supports ((-webkit-background-clip: text) or (background-clip: text))", css)
            # The name gradient defaults on, chained so a user stylesheet
            # wins regardless of load order, and every shipped theme carries
            # its own accent-derived default gradient.
            @test occursin(
                "background-image: var(--landing-name-background, var(--landing-name-background-default, none))",
                css,
            )
            @test occursin(
                "-webkit-text-fill-color: var(--landing-name-color, var(--landing-name-color-default, currentcolor))",
                css,
            )
            @test count("--landing-name-background-default:", css) == 6
            @test count("--landing-glow-default:", css) == 6
            @test occursin("@media (forced-colors: active)", css)
            @test occursin("@media print", css)
            # The glow disc chains the user knob over the shipped per-theme
            # default (a hard-split gradient in the accent hues), so a user
            # stylesheet wins regardless of load order (the plugin's own
            # sheet loads after user assets).
            @test occursin("background: var(--landing-glow, var(--landing-glow-default))", css)
            @test occursin("filter: var(--landing-glow-filter, blur(40px))", css)
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
