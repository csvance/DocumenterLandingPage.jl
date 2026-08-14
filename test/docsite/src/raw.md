# Raw passthrough

A plain `@raw html` block that is **not** landing frontmatter must pass through
to the page unchanged:

```@raw html
<div class="custom-note">hand-written HTML, untouched by the plugin</div>
```

And a code block processed by DocumenterCodeBlocks:

```julia
function add(a, b)
    a + b
end
```
