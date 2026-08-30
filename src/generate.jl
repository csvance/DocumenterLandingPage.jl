# Rendering the landing frontmatter into the hero + features HTML.
#
# The output structure matches the VitePress home layout the frontmatter
# describes (hero block + features block), with class names the bundled
# stylesheet styles. Only the parts present in the YAML are emitted: a hero
# without an image renders no image column, a hero without actions renders no
# button row, a feature without a link renders as a plain tile. A feature's
# icon may be an emoji (or any text, escaped) or an image, with optional
# light/dark theme variants and optional badge wrapping, mirroring
# VitePress's `FeatureIcon` forms.

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
#
# The resolver runs during expansion (order 10.5), before Documenter has
# created the pages' output directories in `build/` (RenderDocument, order
# 6.0). It therefore decides from the frontmatter itself, not from the build
# tree: a target ending in `/` is a directory page and keeps its trailing
# slash, and the `assets/` remap is decided against the *source* tree, which
# always exists at expand time (Documenter copies `src/assets/*` to
# `build/assets/` later, so `build/assets/logo.svg` may or may not exist
# yet).
function _resolve_href(doc, page, target::AbstractString)
    isempty(target) && return target
    startswith(target, "#") && return target
    (
        startswith(target, "http://") || startswith(target, "https://") ||
            startswith(target, "mailto:")
    ) && return target
    if startswith(target, "/")
        t = lstrip(target, '/')
        if isfile(joinpath(doc.user.root, doc.user.source, "assets", t))
            # A bare file under `src/assets/`: it lands in the site's
            # `assets/` directory, mirroring Documenter's own copy.
            resolved = joinpath(doc.user.build, "assets", t)
        else
            # Otherwise it is a site page.
            resolved = joinpath(doc.user.build, t)
        end
        pagedir = dirname(page.build)
        isempty(pagedir) && (pagedir = ".")
        # Both paths are relative to `doc.user.root`; anchor them there so
        # the computation does not depend on the process working directory.
        href = relpath(joinpath(doc.user.root, resolved), joinpath(doc.user.root, pagedir))
        # Directory pages keep the frontmatter's trailing slash so browsers
        # hit the directory directly instead of a redirect hop.
        if endswith(target, "/") && !endswith(href, "/")
            href = string(href, "/")
        end
        return href
    end
    return target
end

# ---------------------------------------------------------------------------
# Inline Markdown for tile details (issue #5).
#
# A feature's `details` is parsed with the Markdown stdlib and rendered
# inline: code spans, emphasis, links, images, and hard line breaks carry
# through, while every text node is escaped exactly like plain details have
# always been. The stdlib parser leaves raw HTML (`<br>`, `<span>`, ...) inside
# plain text nodes, so inline HTML never passes through unescaped. Links and
# image sources resolve through _resolve_href, so a `/tutorial/` written in
# details behaves like every other frontmatter link. Block-level constructs
# have no honest inline rendering: fenced code collapses to an inline <code>,
# and anything else (headers, lists, ...) falls back to the plain escaped
# text of the whole field.

# Render one parsed inline node to HTML. The final `_esc(string(node))` arm
# keeps unknown node types visible (escaped) instead of crashing the build.
function _render_inline_node(node, doc, page)
    node isa AbstractString && return _esc(node)
    node isa Markdown.Code && return "<code>$(_esc(node.code))</code>"
    node isa Markdown.Bold && return "<strong>$(_render_inline(node.text, doc, page))</strong>"
    node isa Markdown.Italic && return "<em>$(_render_inline(node.text, doc, page))</em>"
    node isa Markdown.Link &&
        return "<a href=\"$(_esc(_resolve_href(doc, page, node.url)))\">$(_render_inline(node.text, doc, page))</a>"
    node isa Markdown.Image &&
        return "<img src=\"$(_esc(_resolve_href(doc, page, node.url)))\" alt=\"$(_esc(node.alt))\">"
    node isa Markdown.LineBreak && return "<br>"
    node isa Markdown.HTML && return _esc(node.content)
    return _esc(string(node))
end

function _render_inline(children, doc, page)
    parts = String[]
    for child in children
        push!(parts, _render_inline_node(child, doc, page))
    end
    return join(parts)
end

# Render a feature tile's details string as inline Markdown.
function _render_details(details, doc, page)
    md = Markdown.parse(string(details))
    parts = String[]
    for block in md.content
        if block isa Markdown.Paragraph
            push!(parts, _render_inline(block.content, doc, page))
        elseif block isa Markdown.Code
            push!(parts, "<code>$(_esc(block.code))</code>")
        else
            return _esc(string(details))
        end
    end
    return join(parts, " ")
end

# Does the tile's details parse to inline content containing a Markdown link
# (including links nested inside emphasis and autolinks)? Code spans, images,
# and fenced code are not links and don't count. Used to warn about the
# nested-anchor combination: a tile with a tile-level `link` wraps its whole
# content in an anchor, and HTML forbids an anchor inside an anchor.
function _details_has_link(details)
    md = Markdown.parse(string(details))
    for block in md.content
        block isa Markdown.Paragraph || continue
        _inline_has_link(block.content) && return true
    end
    return false
end

function _inline_has_link(children)
    for child in children
        child isa Markdown.Link && return true
        if child isa Markdown.Bold || child isa Markdown.Italic
            _inline_has_link(child.text) && return true
        end
    end
    return false
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

# Join a list of CSS classes into an HTML class attribute, or "" for none.
function _img_tag(classes, src, alt, width, height)
    cls = isempty(classes) ? "" : " class=\"$(join(classes, " "))\""
    return "<img$(cls) src=\"$(src)\" alt=\"$(alt)\" width=\"$(width)\" height=\"$(height)\">"
end

# Render a feature tile's icon markup.
#
# `icon` accepts the VitePress `FeatureIcon` forms:
#   - a string (emoji is the normal case), or an absent icon: escaped text in
#     the badge box, exactly as the icon has always rendered;
#   - a mapping with `src`: an <img> icon; `wrap: true` puts it in the badge
#     box, otherwise (the default) it renders directly as a tile child;
#   - a mapping with `light`/`dark`: per-theme variants emitted as two <img>s
#     carrying Documenter's shipped .docs-light-only/.docs-dark-only classes,
#     the same mechanism the hero `image.dark` uses. A `src` alongside
#     light/dark wins, mirroring VitePress.
#
# Image paths resolve through _resolve_href, so a root-relative `/icon.svg`
# remaps into the site's assets/ directory like the hero image. `width` and
# `height` default to 48, `alt` to an empty string. A mapping with none of
# src/light/dark emits no icon markup at all.
function _render_feature_icon(icon, doc, page)
    if icon isa AbstractDict
        src = get(icon, "src", "")
        light = get(icon, "light", "")
        dark = get(icon, "dark", "")
        if isempty(src) && isempty(light) && isempty(dark)
            return ""
        end
        alt = _esc(get(icon, "alt", ""))
        width = get(icon, "width", 48)
        height = get(icon, "height", 48)
        wrap = get(icon, "wrap", false) == true
        # Unwrapped images render directly as tile children; the class
        # constrains oversized images (see landing.css). Wrapped ones ride the
        # badge box's own constraint instead.
        outer = wrap ? String[] : String["landing-feature__icon-img"]
        if !isempty(src)
            s = _esc(_resolve_href(doc, page, src))
            imgs = [_img_tag(outer, s, alt, width, height)]
        else
            # Emit only the variants present, each hidden by the theme CSS
            # when it does not apply.
            imgs = String[]
            if !isempty(light)
                l = _esc(_resolve_href(doc, page, light))
                push!(imgs, _img_tag(["docs-light-only"; outer], l, alt, width, height))
            end
            if !isempty(dark)
                d = _esc(_resolve_href(doc, page, dark))
                push!(imgs, _img_tag(["docs-dark-only"; outer], d, alt, width, height))
            end
        end
        if wrap
            return "<div class=\"landing-feature__icon\">\n$(join(imgs, "\n"))\n</div>"
        end
        return join(imgs, "\n")
    end
    return "<div class=\"landing-feature__icon\">$(_esc(string(icon)))</div>"
end

function _render_feature(feature, doc, page)
    icon = _render_feature_icon(get(feature, "icon", ""), doc, page)
    title = _esc(get(feature, "title", ""))
    details = _render_details(get(feature, "details", ""), doc, page)
    inner = "$(icon)\n" *
        "<h2 class=\"landing-feature__title\">$(title)</h2>\n" *
        "<p class=\"landing-feature__details\">$(details)</p>"
    link = get(feature, "link", "")
    if !isempty(link) && _details_has_link(get(feature, "details", ""))
        # Anchors cannot nest: the tile wraps everything in <a>, so a Markdown
        # link in its details would make the browser split the tile into
        # separate fragments. Warn instead of silently emitting broken markup.
        @warn "Feature tile \"$(get(feature, "title", ""))\" on $(page.build) has both a tile link and Markdown links in its details; nested anchors are invalid HTML and the browser splits the tile. Drop the tile's link and let the details links navigate, or keep details to code spans and emphasis on linked tiles."
    end
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
        dark = get(image, "dark", "")
        push!(parts, "  <div class=\"landing-hero__image\">")
        # The logo rides in a fixed square box (mirroring VitePress's
        # .image-container): the stylesheet sizes the box in absolute pixels
        # per breakpoint and the logo and its glow disc proportionally inside
        # it, so the glow can never be squashed, scaled, or clipped by the
        # surrounding columns, whatever the viewport or the logo's aspect
        # ratio does.
        push!(parts, "    <div class=\"landing-hero__image-container\">")
        if !isempty(dark)
            # Optional `dark` variant for dark themes, swapped in by
            # Documenter's own theme CSS: every shipped theme stylesheet
            # compiles `.docs-dark-only { display: none }` (light themes) or
            # `.docs-light-only { display: none }` (dark themes), the same
            # mechanism Documenter's sidebar logo uses.
            dark_src = _esc(_resolve_href(doc, page, dark))
            push!(parts, "      <img class=\"docs-light-only\" src=\"$(src)\" alt=\"$(alt)\" width=\"320\" height=\"320\">")
            push!(parts, "      <img class=\"docs-dark-only\" src=\"$(dark_src)\" alt=\"$(alt)\" width=\"320\" height=\"320\">")
        else
            push!(parts, "      <img src=\"$(src)\" alt=\"$(alt)\" width=\"320\" height=\"320\">")
        end
        push!(parts, "    </div>")
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
