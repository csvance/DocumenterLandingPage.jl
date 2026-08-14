# Automatic asset injection.
#
# Users only add `plugins=[LandingPage()]` — no `assets=` entries. Before
# RenderDocument (6.0), the plugin's bundled stylesheet is copied into
# `build/assets/documenterlandingpage/` and pushed into the HTML format's
# `assets` vector, so Documenter emits the `<head>` `<link>` tag through its
# own machinery (correct per-page relative paths, cached files).

const ASSET_DIR = normpath(joinpath(@__DIR__, "..", "assets"))

abstract type LandingPageAssetStep <: Builder.DocumentPipeline end

Selectors.order(::Type{LandingPageAssetStep}) = 5.5   # before RenderDocument (6.0)

function Selectors.runner(::Type{LandingPageAssetStep}, doc::Documenter.Document)
    html = _findfirst_html(doc)
    html === nothing && return

    files = String["landing.css"]

    dest = joinpath(doc.user.build, "assets", "documenterlandingpage")
    mkpath(dest)
    for f in files
        cp(joinpath(ASSET_DIR, f), joinpath(dest, f); force = true)
        uri = "assets/documenterlandingpage/$(f)"
        _has_asset(html.assets, uri) || push!(html.assets, Documenter.asset(uri; islocal = true))
    end
    return
end

function _findfirst_html(doc::Documenter.Document)
    return _findfirst_html(doc.user.format)
end

function _findfirst_html(formats::AbstractVector)
    for fmt in formats
        fmt isa Documenter.HTMLWriter.HTML && return fmt
    end
    return nothing
end

_has_asset(assets, uri) =
    any(a -> a isa Documenter.HTMLWriter.HTMLAsset && a.uri == uri, assets)
