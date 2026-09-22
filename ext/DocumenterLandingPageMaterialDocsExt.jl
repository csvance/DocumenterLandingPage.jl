# MaterialDocs support.
#
# `MaterialDocs.Material3 <: Documenter.Writer` is a sibling of
# `Documenter.HTML`, not a subtype of it: it validates the Documenter.HTML
# keywords by constructing one, keeps it in its `html` field, and renders that
# vector's assets into `<head>` after its own stylesheet. So the plugin's
# asset step only needs to be told where the settings live, and which extra
# stylesheet maps the `--landing-*` properties onto MaterialDocs' MD3 tokens.
#
# Everything else in the plugin is already writer-agnostic: expansion runs in
# ExpandTemplates, before any writer is chosen, and MaterialDocs passes
# `Documenter.RawNode(:html, ...)` through unchanged.

module DocumenterLandingPageMaterialDocsExt

import DocumenterLandingPage
import MaterialDocs

DocumenterLandingPage._html_settings(fmt::MaterialDocs.Material3) = fmt.html

DocumenterLandingPage._extra_stylesheets(::MaterialDocs.Material3) =
    String["landing-material.css"]

end # module
