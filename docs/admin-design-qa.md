# Admin product design QA

## Source truth

- Pinned Medusa source commit:
  `bda24b9725ac697ec5e8f706b503013e20babf12`.
- Shell source:
  `packages/admin/dashboard/src/components/layout/main-layout/main-layout.tsx`
  and `shell/shell.tsx`.
- Product source:
  `packages/admin/dashboard/src/routes/products/product-list/product-list.tsx`
  and `components/product-list-table/product-list-table.tsx`.
- Product-detail source:
  `packages/admin/dashboard/src/routes/products/product-detail/product-detail.tsx`
  plus its General, Media, Options, Variants, Sales Channels, Shipping,
  Organization and Attributes section components.
- Rendered reference: Medusa's official Admin product-list image in the User
  Guide and official product-detail image in the Edit Product guide.
- Prototype: the authenticated Morrow Admin at port `13002`, backed by the
  local API on a temporary database.

## Compared state

The list renders use the light product-list state with Products selected, four
or more published products, no active filters, and the first page. The detail
renders use a published sweatpants product with two images, one Size option,
inventory variants, collection, category, tags and weight.

The official product-detail source and the running prototype were emitted
together at a `1280 x 720` browser surface. The reference raster is itself
letterboxed and scaled inside that surface, so this establishes structural,
spacing, hierarchy and responsive fidelity rather than pixel identity.

## Verified

- The 220px navigation hierarchy, selected row, nested product links, merchant
  identity and bottom utilities follow the pinned shell source.
- The 48px top bar, 12px main gutter, neutral bordered container, title/actions
  header, filter/search/order toolbar, dense table and server-owned pagination
  follow the product-list source.
- Sign-in, session restoration, product loading, title-or-handle search,
  pagination, responsive drawer, notifications, theme selection and sign-out
  are wired. Controls whose backend operation is not implemented report that
  they require the next Admin API slice.
- Remote merchant thumbnails use Flutter's HTML image strategy on web because
  Medusa's public seed CDN omits CORS headers.
- Clicking a real product opens its authenticated detail. General, ordered
  media, options, variants, organization and attributes are API-backed; the
  two-column desktop layout collapses into one column below 900px.
- Sales Channels and Shipping configuration remain visible and explicitly say
  `Not configured` because those Medusa domains do not yet exist in this
  schema. No fake merchant data is rendered.

## Open findings

- P2 — Capture an unletterboxed Medusa source at the same content width before
  declaring pixel parity. The current combined comparison passes structural
  design QA, not a pixel-diff threshold.
- P1 — Create/edit, import/export, filters, ordering, media mutation, option
  mutation and variant mutation remain feature work under issue #31. Their
  visible controls deliberately do not pretend that an API mutation succeeded.

## Result

Passed for the implemented read-only product-list and product-detail vertical
slices. Broader Medusa Admin feature parity is not claimed.
