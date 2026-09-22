# Automatic asset injection.
#
# Users only add `plugins=[LandingPage()]` — no `assets=` entries. Before
# RenderDocument (6.0), the plugin's bundled stylesheet is copied into
# `build/assets/documenterlandingpage/` and pushed into the HTML format's
# `assets` vector, so Documenter emits the `<head>` `<link>` tag through its
# own machinery (correct per-page relative paths, cached files).
#
# Third-party writers: a writer other than `Documenter.HTML` that still emits
# an HTML site (MaterialDocs' `Material3`, say) usually validates its
# Documenter.HTML keywords by constructing one and keeps it in a field. Such a
# writer opts in by adding two methods, from a package extension:
#
#   DocumenterLandingPage._html_settings(::TheirWriter) -> their Documenter.HTML
#   DocumenterLandingPage._extra_stylesheets(::TheirWriter) -> ["their-map.css"]
#
# The first says where the `<head>` assets go, the second names a stylesheet
# that maps the `--landing-*` custom properties onto that writer's own palette
# (landing.css ships the mapping for Documenter's shipped themes only). A
# writer with no methods is skipped, which is what every non-HTML writer wants.

const ASSET_DIR = normpath(joinpath(@__DIR__, "..", "assets"))

"""
    _html_settings(format) -> Union{Documenter.HTMLWriter.HTML, Nothing}

The HTML settings object a writer routes its `<head>` assets through, or
`nothing` for a writer that has none.
"""
_html_settings(fmt::Documenter.HTMLWriter.HTML) = fmt
_html_settings(::Documenter.Writer) = nothing

"""
    _extra_stylesheets(format) -> Vector{String}

Stylesheets a writer needs on top of `landing.css`, as file names under
`assets/`. Empty for Documenter's own HTML, whose themes `landing.css`
already carries.
"""
_extra_stylesheets(::Documenter.Writer) = String[]

abstract type LandingPageAssetStep <: Builder.DocumentPipeline end

Selectors.order(::Type{LandingPageAssetStep}) = 5.5   # before RenderDocument (6.0)

function Selectors.runner(::Type{LandingPageAssetStep}, doc::Documenter.Document)
    dest = joinpath(doc.user.build, "assets", "documenterlandingpage")
    # Every writer in the vector gets its own <link>s: a two-format build
    # renders the same landing page twice, through two writers.
    for fmt in doc.user.format
        html = _html_settings(fmt)
        html === nothing && continue
        mkpath(dest)
        for f in ["landing.css"; _extra_stylesheets(fmt)]
            cp(joinpath(ASSET_DIR, f), joinpath(dest, f); force = true)
            uri = "assets/documenterlandingpage/$(f)"
            _has_asset(html.assets, uri) ||
                push!(html.assets, Documenter.asset(uri; islocal = true))
        end
    end
    return
end

_has_asset(assets, uri) =
    any(a -> a isa Documenter.HTMLWriter.HTMLAsset && a.uri == uri, assets)
