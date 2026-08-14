```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: ReactantServer.jl
  text: Production inference for Reactant-compiled models
  tagline: KServe V2 over gRPC from one GPU to many, with compiled XLA models, Julia-first pre and postprocessing, and the most models per card.
  actions:
    - theme: brand
      text: Tutorial
      link: /tutorial/
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/EnzymeAD/ReactantServer.jl
  image:
    src: /logo.svg
    alt: ReactantServer.jl

features:
  - icon: ⚡
    title: KServe V2, natively
    details: Speaks the KServe V2 inference API over gRPC, so standard Triton and KServe clients connect unchanged.
    link: /client/
  - icon: 🚀
    title: XLA under the hood
    details: Models compile ahead of time through Reactant and XLA into device executables; the runtime is device agnostic, CUDA today with CPU for development.
    link: /tutorial/
  - icon: 🧩
    title: Julia-first
    details: A bundle's model.jl registers pre and postprocessing in plain Julia, and every convention follows Julia's, column-major with the batch axis last.
    link: /bundles/
  - icon: 💾
    title: On-demand weights
    details: Weights stay in host RAM and stream to the GPU under an LRU byte budget, so a card serves more models than fit in VRAM.
    link: /on_demand_weights/
  - icon: 🔀
    title: A coalescing scheduler
    details: A deficit-weighted, cost-aware scheduler merges same-model requests into one execution at a compiled batch size.
    link: /scheduling/
  - icon: 🔁
    title: Hot reload
    details: In dynamic mode the server watches the model repository and reloads bundles online, with no restart.
    link: /bundles/
---
```

## What it is

ReactantServer.jl is a production inference server for XLA-accelerated models.
The landing page above is rendered from the YAML frontmatter in the `@raw html`
block, exactly as VitePress used to render it.

## Start here

- The [Tutorial](tutorial.md).
- The [API](api.md).
