# Rendering the landing frontmatter into the hero + features HTML.
#
# The output structure matches the VitePress home layout the frontmatter
# describes (hero block + features block), with class names the bundled
# stylesheet styles. Only the parts present in the YAML are emitted: a hero
# without an image renders no image column, a hero without actions renders no
# button row, a feature without a link renders as a plain tile.

# Escape text going into HTML so YAML copy cannot break the markup.
function _esc(s::AbstractString)
    s = replace(s, "&" => "&amp;")
    s = replace(s, "<" => "&lt;")
    s = replace(s, ">" => "&gt;")
    s = replace(s, "\"" => "&quot;")
    return s
end

# Resolve a frontmatter href (or image src) to a page-relative URL:
#
#   - external URLs, fragments, and mailto: pass through unchanged;
#   - root-relative paths ("/tutorial/", "/logo.svg") resolve against the
#     built site root, with bare filenames remapped into the site's `assets/`
#     directory (Documenter copies `src/assets/*` there; VitePress-style
#     frontmatter references such files by bare name);
#   - anything else is already relative to the page and passes through.
function _resolve_href(doc, page, target::AbstractString)
    isempty(target) && return target
    startswith(target, "#") && return target
    (startswith(target, "http://") || startswith(target, "https://") ||
     startswith(target, "mailto:")) && return target
    if startswith(target, "/")
        t = lstrip(target, '/')
        resolved = nothing
        for candidate in (joinpath(doc.user.build, t), joinpath(doc.user.build, "assets", t))
            if isdir(candidate) || isfile(candidate)
                resolved = candidate
                break
            end
        end
        resolved === nothing && (resolved = joinpath(doc.user.build, t))
        pagedir = dirname(page.build)
        isempty(pagedir) && (pagedir = ".")
        href = relpath(resolved, pagedir)
        # Keep the frontmatter's trailing slash for directory targets so
        # browsers hit the directory directly instead of a redirect hop.
        if endswith(target, "/") && isdir(resolved)
            href = string(href, "/")
        end
        return href
    end
    return target
end

function _render_actions(actions, doc, page)
    isempty(actions) && return ""
    parts = String[]
    for a in actions
        theme = get(a, "theme", "alt") == "brand" ? "landing-btn--brand" : "landing-btn--alt"
        text = _esc(get(a, "text", ""))
        href = _esc(_resolve_href(doc, page, get(a, "link", "#")))
        push!(parts, "<a class=\"landing-btn $(theme)\" href=\"$(href)\">$(text)</a>")
    end
    return join(parts, "\n      ")
end

function _render_feature(feature, doc, page)
    icon = _esc(get(feature, "icon", ""))
    title = _esc(get(feature, "title", ""))
    details = _esc(get(feature, "details", ""))
    inner = "<div class=\"landing-feature__icon\">$(icon)</div>\n" *
        "<h2 class=\"landing-feature__title\">$(title)</h2>\n" *
        "<p class=\"landing-feature__details\">$(details)</p>"
    link = get(feature, "link", "")
    if isempty(link)
        return "<div class=\"landing-feature\">\n$(inner)\n  </div>"
    else
        href = _esc(_resolve_href(doc, page, link))
        return "<a class=\"landing-feature\" href=\"$(href)\">\n$(inner)\n  </a>"
    end
end

function _render_landing(data::AbstractDict, doc, page)
    hero = get(data, "hero", Dict{Any, Any}())
    hero isa AbstractDict || (hero = Dict{Any, Any}())

    parts = String["<div id=\"landing\" class=\"landing\">"]
    push!(parts, "<header class=\"landing-hero\">")
    push!(parts, "  <div class=\"landing-hero__text\">")
    name = get(hero, "name", "")
    isempty(name) || push!(parts, "    <p class=\"landing-name\">$(_esc(name))</p>")
    text = get(hero, "text", "")
    isempty(text) || push!(parts, "    <h1 class=\"landing-title\">$(_esc(text))</h1>")
    tagline = get(hero, "tagline", "")
    isempty(tagline) || push!(parts, "    <p class=\"landing-tagline\">$(_esc(tagline))</p>")
    actions = get(hero, "actions", Any[])
    rendered_actions = _render_actions(actions isa AbstractVector ? actions : Any[], doc, page)
    isempty(rendered_actions) ||
        push!(parts, "    <div class=\"landing-actions\">\n$(rendered_actions)\n    </div>")
    push!(parts, "  </div>")

    image = get(hero, "image", Dict{Any, Any}())
    if image isa AbstractDict && !isempty(get(image, "src", ""))
        src = _esc(_resolve_href(doc, page, image["src"]))
        alt = _esc(get(image, "alt", ""))
        push!(parts, "  <div class=\"landing-hero__image\">")
        push!(parts, "    <img src=\"$(src)\" alt=\"$(alt)\" width=\"320\" height=\"320\">")
        push!(parts, "  </div>")
    end
    push!(parts, "</header>")

    features = get(data, "features", Any[])
    if features isa AbstractVector && !isempty(features)
        push!(parts, "<section class=\"landing-features\" aria-label=\"Features\">")
        for feature in features
            feature isa AbstractDict || continue
            push!(parts, "  $(_render_feature(feature, doc, page))")
        end
        push!(parts, "</section>")
    end

    push!(parts, "</div>")
    return join(parts, "\n")
end
