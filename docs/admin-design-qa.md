# Admin product-list design QA

## Source truth

- Pinned Medusa source commit:
  `bda24b9725ac697ec5e8f706b503013e20babf12`.
- Shell source:
  `packages/admin/dashboard/src/components/layout/main-layout/main-layout.tsx`
  and `shell/shell.tsx`.
- Product source:
  `packages/admin/dashboard/src/routes/products/product-list/product-list.tsx`
  and `components/product-list-table/product-list-table.tsx`.
- Rendered reference: Medusa's official Admin product-list image in the User
  Guide.
- Prototype: the authenticated Morrow Admin at port `13002`, backed by the
  local API on a temporary database.

## Compared state

Both renders use the light product-list state with the Products navigation item
selected, four or more published products, no active filters, and the first
page. Merchant product names, collections, thumbnails, sales-channel values and
variant counts are data differences rather than visual drift.

The source and prototype were emitted together for full-view comparison. The
official image is a desktop capture; the available Codex in-app browser surface
was `505 x 583`, so the prototype correctly used its responsive drawer and
horizontal table safety. An equal-width desktop raster is still required before
claiming pixel parity.

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

## Open findings

- P2 — Capture the source and prototype at one equal desktop viewport before
  declaring pixel parity. The compact render and pinned source establish
  responsive and structural fidelity, not a same-raster result.
- P1 — Product detail, create/edit, import/export, filters and ordering remain
  feature work under issue #31. Their visible controls deliberately do not
  pretend that an API mutation succeeded.
