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
- Product-edit source:
  `packages/admin/dashboard/src/routes/products/product-edit/product-edit.tsx`,
  `components/edit-product-form/edit-product-form.tsx`, and
  `packages/admin/dashboard/src/components/common/switch-box/switch-box.tsx`.
- Product-create source:
  `packages/admin/dashboard/src/routes/products/product-create/product-create.tsx`
  and the Details, Organize and Variants form components beneath it.
- Rendered reference: Medusa's official Admin product-list image in the User
  Guide, official product-detail image in the Edit Product guide, and official
  Details-step image in the Create Product guide.
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

The general-edit comparison uses the pinned RouteDrawer implementation as
source truth: right-side drawer, Medusa field order, lifecycle selector,
discountable switch box, and sticky Cancel/Save footer.

The product-create comparison puts the official Medusa Details-step reference
and the running Morrow form into one `2560 x 720` image. Both sides use a
`1280 x 720` viewport and the same empty Details state. This is a direct
head-to-head inspection, not two separately judged screenshots.

The media follow-up uses the same official raster and running implementation in
the in-app browser at `505 x 583`. The source remains letterboxed, so this pass
verifies hierarchy, field order, upload proportions and compact behavior rather
than pixel identity.

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
- The General-section action opens an API-backed edit drawer. Real update,
  optional-value clearing, all four lifecycle transitions, automatic detail and
  list refresh, validation, and duplicate-handle conflict states were exercised
  against the temporary local database.
- Create opens the source-shaped full-screen focus surface with progress tabs,
  General fields, automatic handle, variant enablement, option/value setup,
  Organize attributes, regional price and inventory controls, and draft/publish
  actions. A two-variant product was published in the browser, opened in admin
  detail, and then rendered by handle in the storefront with its USD price.
- Creation failures are atomic: duplicate handle, duplicate SKU, incomplete
  option selection and incomplete active-currency pricing are covered by server
  integration tests. The generated admin client is exercised by non-widget
  view-model tests.
- Details now includes the source-positioned Media section. Real files use the
  generated multipart client, server byte limits and signature detection; rows
  can be reordered, removed or made thumbnail. Publication verifies each staged
  file, stores ordered image rows atomically, exposes them through the separate
  storefront contract, and blocks staged deletion after attachment.
- Sales Channels and Shipping configuration remain visible and explicitly say
  `Not configured` because those Medusa domains do not yet exist in this
  schema. No fake merchant data is rendered.

## Open findings

- P2 — Capture an unletterboxed Medusa source at the same content width before
  declaring pixel parity. The current combined comparison passes structural
  design QA, not a pixel-diff threshold.
- P1 — Import/export, filters, ordering, post-create media/option/variant
  mutation and multiple option axes in the Flutter creation form remain feature
  work under issue #31. Their visible controls do not pretend an API mutation
  succeeded.
- P1 — The filesystem adapter is durable for one server node. Multi-node
  deployment still needs object storage and cleanup for uploads left staged
  after an abandoned browser session.

## Result

Passed for the implemented product-list, product-detail, general-edit and
product-create-with-media vertical slices. Broader Medusa Admin parity is not
claimed.

final result: passed
