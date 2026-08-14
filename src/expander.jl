# The `@raw html` interception: the expander that turns landing frontmatter
# into the hero + features HTML.
#
# Documenter's own raw pass-through expander (RawBlocks) runs at order 11.0,
# and Selectors dispatch runs the lowest order first, stopping at the first
# match. This expander sits at 10.5 and claims a block only when it is
# `@raw html` AND its content is VitePress landing frontmatter (`layout:
# home`); everything else falls through to Documenter's RawBlocks untouched.

abstract type LandingPageExpander <: Expanders.NestedExpanderPipeline end

Selectors.order(::Type{LandingPageExpander}) = 10.5   # before RawBlocks (11.0)

function _is_landing_frontmatter(code::AbstractString)
    s = strip(code)
    startswith(s, "---") || return false
    return occursin(r"(?m)^\s*layout\s*:\s*home\s*$", s)
end

function Selectors.matcher(::Type{LandingPageExpander}, node, page, doc)
    x = node.element
    x isa Documenter.MarkdownAST.CodeBlock || return false
    occursin(r"^@raw\s+html$", x.info) || return false
    return _is_landing_frontmatter(x.code)
end

function Selectors.runner(::Type{LandingPageExpander}, node, page, doc)
    x = node.element
    data = YAML.load(x.code)
    node.element = Documenter.RawNode(:html, _render_landing(data, doc, page))
    return
end
