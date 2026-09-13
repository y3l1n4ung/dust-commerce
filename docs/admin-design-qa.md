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
- Product-query source:
  `hooks/table/query/use-product-table-query.tsx`,
  `hooks/table/filters/use-product-table-filters.tsx`, and the shared
  DataTable filter and order-by components at the pinned commit.
- Product-detail source:
  `packages/admin/dashboard/src/routes/products/product-detail/product-detail.tsx`
  plus its General, Media, Options, Variants, Sales Channels, Shipping,
  Organization and Attributes section components.
- Product-delete source:
  `components/product-list-table/product-list-table-actions.tsx`, the detail
  `product-general-section.tsx`, `hooks/api/products.tsx`, and the English
  product deletion translations at the pinned commit.
- Product-edit source:
  `packages/admin/dashboard/src/routes/products/product-edit/product-edit.tsx`,
  `components/edit-product-form/edit-product-form.tsx`, and
  `packages/admin/dashboard/src/components/common/switch-box/switch-box.tsx`.
- Product-create source:
  `packages/admin/dashboard/src/routes/products/product-create/product-create.tsx`
  and the Details, Organize and Variants form components beneath it.
- Product-media source:
  `packages/admin/dashboard/src/routes/products/product-media/` and the
  product-detail `product-media-section.tsx` at the pinned commit.
- Image-variant source:
  `packages/admin/dashboard/src/routes/products/product-image-variants-edit/`
  plus the image command bar in `product-media-section.tsx` at the pinned
  commit.
- Variant-edit source:
  `packages/admin/dashboard/src/routes/product-variants/product-variant-edit/`
  and its `product-edit-variant-form.tsx` at the pinned commit.
- Variant-pricing source:
  `packages/admin/dashboard/src/routes/products/product-prices/pricing-edit.tsx`,
  `packages/admin/dashboard/src/routes/products/common/variant-pricing-form.tsx`
  and the shared DataGrid currency cell at the pinned commit.
- Product-option source:
  `packages/admin/dashboard/src/routes/products/product-detail/components/product-option-section/`
  and `packages/admin/dashboard/src/routes/product-options/product-option-edit/`
  at the pinned commit.
- Global product-option source:
  `packages/admin/dashboard/src/routes/product-options/product-option-list/`,
  `product-option-detail/`, and `product-option-create/` at the pinned commit.
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

The post-create detail-card pair uses Medusa's official `1516 x 853` media
section raster and Morrow's running product detail, each captured in a
`1280 x 720` in-app browser surface and combined into one `2560 x 720` image.
The current pinned source selects Medusa's two-column layout; the older guide
raster crops that surrounding layout, so card tokens and content are directly
comparable while page-column width is not. The editor implementation was
captured at `1280 x 720`, but no same-state Medusa editor raster is available.

The image-variant drawer was exercised at `505 x 583`: one selected image opens
the right-side surface with its 80px preview, search, tri-state selection,
Title/SKU/Thumbnail columns and Cancel/Save footer. Medusa publishes no
same-state association-drawer raster, so source structure and browser behavior
are verified but pixel comparison remains blocked.

The variant-detail comparison uses live Medusa `2.20.1` and Morrow drawers in
the in-app browser at equal `1280 x 720` viewports. The two captures were
combined into one `2560 x 720` image before judging the implementation.

The product-option comparison uses the same live source, browser, viewport and
combined-image method. Both drawers use dark theme and four values. Their value
orders differ because each isolated database supplies a different persisted
rank; the layout and ordering behavior are directly comparable.

The global product-option list and Size detail use live Medusa `2.20.1` and
Morrow in light theme. The `1291 x 772` Medusa captures were center-cropped to
the same `1280 x 720` content surface as Morrow, then each pair was combined
into one `2560 x 720` image. Merchant fixtures and value rank differ; shell,
cards, tables, searches, status labels, result counts and pagination are
directly comparable.

The global product-option create comparison uses the same normalized live
source/build method and the same empty form state. Both render the full-screen
focus surface, 720px content column, title and value fields, close/esc chrome,
and sticky Cancel/Save footer in one `2560 x 720` comparison.

The variant-pricing pass uses the pinned source code as structural truth and
the running Morrow screen at `1280 x 720`. The local Medusa process continued
serving its Admin route, but its existing in-app-browser tab stopped responding
to capture, so this pass does not claim same-state pixel parity.

The product-stock pass uses Medusa's pinned `product-stock` route, form, schema
and DataGrid columns as structural truth. Morrow keeps the full-screen header,
variant title/SKU rows and sticky Cancel/Save footer, but maps the location
columns to its real aggregate inventory model instead of showing fake stock
locations. The Morrow screen and end-to-end mutation were captured live; the
local Medusa tab again timed out, so pixel parity is not claimed.

The product-delete pass uses the pinned list and detail action-group source as
structural truth. Morrow exposes Edit followed by a separately divided Delete
action and uses Medusa's exact confirmation and success/error text. The local
Medusa tab again timed out during capture, so this pass verifies source
structure and live behavior without claiming same-state pixel parity.

The product-query comparison uses live Medusa and Morrow product lists in the
in-app Browser at equal `1280 x 720` viewports, light theme, four published
products and the filter menu open. Both neutral and menu states were combined
into `2560 x 720` images before judging. Morrow omits Sales Channel because its
schema has no such domain; the remaining filter order and labels match source.

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
- Existing-product media now opens a source-shaped focus surface. Upload,
  four-column drag ordering, selection, deletion, thumbnail promotion, Cancel
  cleanup and Save are wired to one authenticated generated-client operation.
  A browser pass reordered two real images, changed the thumbnail, saved, and
  confirmed compact ranks plus the new thumbnail in SQLite. Browser logs had no
  errors.
- Selecting one media item exposes Delete and Manage associated variants. The
  drawer persists add/remove deltas through the guarded generated client,
  refreshes detail state, and reopens with the saved checkbox state. Cross-
  product, overlapping and stale-image mutations are rejected atomically, and
  deleting media removes its stale associations.
- Clicking a variant row opens the supported right-side editor. Its generated
  client reaches a route-level guarded API for title, material, SKU, EAN, UPC,
  barcode, physical/customs attributes, ordered option selections, inventory
  policy and backorder policy. The 560px inset drawer, sticky chrome, exact
  hints, compact switches and searchable 250-country selector match the live
  Medusa drawer. Server integration tests cover authorization, ownership,
  conflicts, database-owned timestamps and storefront readback; non-widget
  view-model tests cover refreshed state and display-safe failures. Browser QA
  saved Denmark, observed success, reopened the drawer and confirmed readback.
- Clicking a product option opens the 560px inset editor for its title, chips
  and persisted rank. The generated Admin client reaches a route-level guarded,
  transactional API that rejects wrong ownership, duplicate titles, invalid
  values and removal of values used by active variants. Browser QA renamed the
  option, added a value, confirmed the refreshed Admin detail and storefront
  readback, then restored the canonical fixture. Non-widget Admin tests include
  distinct display-safe messages for both 409 cases.
- The Products sub-navigation now exposes Medusa's global Options list. The
  generated authenticated client loads, searches, paginates, creates and opens
  safe option detail responses; detail search filters real values and products,
  and edits refresh both routes. The source-shaped action menus also delete
  unused options through a route-guarded soft-delete transaction and return a
  display-safe conflict while an active product still uses the option. Browser
  QA searched values and products, created and deleted a temporary Material
  option, rejected deletion of linked Size, edited Size, restored the canonical
  fixture and observed no application error. Twenty-one non-widget Admin and
  258 server tests pass; no widget tests were added.
- Each variant action now opens Medusa's full-screen pricing focus surface with
  a read-only title column, active-currency columns and sticky Cancel/Save
  controls. A route-level guarded generated client replaces the complete price
  graph transactionally and returns the refreshed direct SQLx response.
  Currency fields use ISO 4217 precision and exact integer conversion rather
  than assuming two decimals or using floating point. Browser QA changed EUR
  and USD, observed the new USD value immediately on the storefront, then
  restored both canonical values. Twenty-six non-widget Admin and 265 server
  tests pass; no widget tests were added.
- Variants now expose Medusa's product-level Edit stock action. The full-screen
  grid saves every shown variant through one route-guarded generated-client
  request, with editable aggregate quantity and inventory management policy.
  Browser QA changed a real variant to 7 unmanaged units, confirmed the
  separate Store response immediately returned that state, then restored 20
  managed units. Empty, duplicate, negative and cross-product selections are
  rejected before partial writes. Twenty-eight non-widget Admin and 269 server
  tests pass; no widget tests were added.
- Product list rows and the detail General card now expose one shared
  source-shaped Edit/Delete action menu. Browser QA deleted a temporary
  published product through the confirmation, observed the row disappear and
  independently received Store `404`. SQLite retained the product, variant and
  two price rows with generated deletion timestamps. Global options remain
  active, while product-exclusive options are retired transactionally. Thirty
  non-widget Admin and 273 server tests pass; no widget tests were added.
- The generated Admin client and ViewModel now carry server-owned status,
  ordering and pagination together. Focused HTTP tests cover multiple status
  values, all six supported sort values, filtering before paging, stable
  counts, and `400` responses for unknown values. Live API QA returned exact
  ascending and descending title order and rejected `order=handle`. Thirty-two
  non-widget Admin and 276 server tests pass; no widget tests were added.
- The same generated query path now carries tag ids and Medusa's JSON
  `created_at` / `updated_at` comparisons. SQL applies them before both count
  and paging; invalid ids, operators, offset-free dates and reversed ranges
  return `400`. Live API QA returned zero rows for an unknown tag and a future
  creation bound, then rejected `$after`. Thirty-three non-widget Admin and 280
  server tests pass; no widget tests were added.
- Product types now follow the pinned Medusa list and product-filter sources:
  a normalized table, guarded `/admin/product-types` discovery, and `type_id`
  filtering live behind the generated Admin client. Store and Admin detail
  responses independently return the display label rather than the internal
  id. Fresh-database API QA proved `401`, search/paging, one matching product,
  malformed-id `400`, and Store readback. Thirty-four non-widget Admin and 284
  server tests pass; all 39 migrations also pass real SQLx run/revert.
- Product query controls now expose source-ordered Type, Tag, Status, Created
  and Updated filters, real discovery choices, removable active controls,
  Clear all and all six supported sort values. The head-to-head pass corrected
  the stretched card, column proportions, row and pagination density, source
  copy, status indicator, menu order, menu size and surface color. Live QA
  filtered the table to Shirt, proved the removal button's accessible label,
  and restored all four products. Thirty-six non-widget Admin and 287 server
  tests pass; all 39 migrations apply and revert without remaining tables.
- Product Types now have the pinned Settings list, create focus modal and edit
  drawer backed by guarded CRUD routes. Product creation and the detail
  Organize drawer select the same stable ids, support explicit Unassigned, and
  refresh the allowlisted product detail after save. Live QA exposed all five
  fixture types, assigned Pants, cleared the type, and restored Shirt; the Store
  boundary still receives only the label. Forty non-widget Admin and 298 server
  tests pass; no widget tests were added.
- Selecting a Product Type now opens the pinned single-column detail layout:
  identity actions, a separately searchable and sortable 10-row Products table,
  then safe Metadata and JSON cards. Live QA opened Shirt with six demo products,
  narrowed the server result to Sample Pocket Tee, reversed and restored title
  order, and opened a linked product detail. Browser logs had no errors. The
  authenticated shell was split below the 180-line gate, reducing legacy LOC
  failures to twelve. Forty-two non-widget Admin tests pass; no widget tests
  were added.
- Product creation now reproduces Medusa's option permutation behavior across
  multiple axes. Live QA generated Size × Color in source order, reduced four
  combinations to two, and proved the surviving S / Black variant retained its
  entered EUR price. A protected integration test round-trips the same complete
  graph. Forty-six non-widget Admin and 299 server tests pass; splitting the
  create screen reduced legacy LOC failures to eleven.
- Sales Channels and Shipping configuration remain visible and explicitly say
  `Not configured` because those Medusa domains do not yet exist in this
  schema. No fake merchant data is rendered.

## Open findings

- P2 — Capture an unletterboxed Medusa source at the same content width before
  declaring pixel parity. The current combined comparison passes structural
  design QA, not a pixel-diff threshold.
- P1 — Product import/export remains unavailable.
- P3 — Global option creation uses comma entry rather than Medusa's interactive
  chip input and post-entry rank organizer. Persisted ordering works, but this
  interaction is not yet a literal copy.
- P3 — The global list keeps its required Global filter as one fixed chip;
  Medusa's removable segmented filter and Clear all interaction are not yet
  implemented.
- P2 — The post-create editor lacks a same-state rendered Medusa source capture.
  The implementation matches the pinned source structure—full focus modal,
  four-column gallery, 24px grid gap, 560px upload panel and sticky footer—but
  code inspection is not a pixel comparison. Run Medusa Admin locally with
  equivalent product data, capture both editors, and repeat the combined pass.
- P1 — The filesystem adapter is durable for one server node. Multi-node
  deployment still needs object storage and cleanup for uploads left staged
  after an abandoned browser session.

## Result

Passed for the implemented product-list, product-detail, general-edit,
product-create-with-media, post-create media-card, image-variant and
variant-detail, product-option-edit and global product-option behavior slices.
Variant-detail, product-option-edit and global product-option list/detail visual
parity now pass same-state live comparisons. Global product-option creation
also passes its same-state empty-form comparison.
Variant pricing, product stock and product deletion pass source-structure and
live end-to-end behavior checks. Product query behavior, discovery and visible
controls pass API, state, accessibility and same-state live comparison.
Post-create editor, image-variant drawer, variant pricing, product stock and
product deletion remain blocked on same-state source captures; broader Medusa
Admin parity is not claimed.

final result: blocked
