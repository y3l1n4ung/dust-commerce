# Storefront design QA

Source visual truth paths:

- Pinned source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/app/[countryCode]/(main)/order/[id]/transfer/[token]/page.tsx`
- Rendered reference: `https://next.medusajs.com/dk/order/order_qa/transfer/demo-capability?qa=matched-final`
- Pinned catalogue source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/store/templates/paginated-products.tsx`
- Rendered catalogue reference: `https://next.medusajs.com/dk/store?qa=store-grid-final`
- Pinned product source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/products/templates/index.tsx`
- Rendered product reference: `https://next.medusajs.com/dk/products/espresso-cup?v_id=variant_01KA906CNZ2951NNN2GDFV1QF8`
- Pinned empty-cart source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/cart/components/empty-cart-message/index.tsx`
- Rendered empty-cart reference: `https://next.medusajs.com/dk/cart?qa=cart-empty-audit`
- Pinned populated-cart sources: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/cart/templates/{index,items,summary}.tsx`, `components/{item,sign-in-prompt}/index.tsx`, and `modules/layout/components/cart-dropdown/index.tsx`
- Rendered populated-cart reference: `https://next.medusajs.com/dk/cart?qa=populated-cart-source`
- Rendered cart-preview reference: `https://next.medusajs.com/dk/products/iphone-16-bundle?qa=cart-preview-source-ready`
- Pinned public-account sources: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/account/templates/account-layout.tsx`, `login-template.tsx`, and `components/{login,register}/index.tsx`
- Rendered public-account reference: `https://next.medusajs.com/dk/account?qa=account-signed-out`

Implementation screenshot paths: in-app browser captures of the transfer route
`http://127.0.0.1:13001/store?qa=store-grid-final`, and
`http://127.0.0.1:13001/products/shorts?qa=product-audit`, and
`http://127.0.0.1:13001/cart?qa=cart-after-restart`, and
`http://127.0.0.1:13001/cart?qa=populated-cart-restarted`, and
`http://127.0.0.1:13001/products/shorts?v_id=var_shorts_s`, and
`http://127.0.0.1:13001/account?qa=account-register-local`. The browser captures
are retained in the task evidence rather than exported into the repository.

Viewport: the matched desktop captures used the same in-app browser surface. The
reference raster was `1265 x 712`; the implementation raster was `1280 x 720`.
The reference's visible scrollbar produced the small raster-size difference.
Compact `390 x 844` transfer and authenticated account-form captures remain.

Pixel dimensions, CSS size, and density normalization: both captures used the
in-app browser's default CSS viewport and density. Comparison normalized the
implementation by the reference-to-implementation ratio (`1265 / 1280`); no
finding was filed from the scrollbar or raster-size difference.

State: the public transfer page used the same `order_qa`, unused demo
capability, English locale, light theme and idle decision state. The catalogue
comparison used each backend's first unfiltered product page; product names and
images therefore differ, while the page structure and layout contract are
directly comparable. The product comparison likewise used the reference
Espresso Cup and Morrow's seeded Everyday Shorts, so option controls and copy
differ while column geometry remains comparable. The populated-cart pair used
one product line from each backend, and the cart-preview pair captured the
post-add panel while it was visibly open. Product names, prices and quantities
are merchant data differences; table and panel geometry are directly
comparable. Remaining global QA covers the product route at compact width and
in selected/out-of-stock states,
`/store` at compact width and with the shared footer visible, authenticated
`/checkout` with a saved address available, authenticated `/account` with a
completed profile, saved addresses and recent orders,
`/account/orders/details/:id`, the authenticated transfer-request form and its
success/error states, the profile password editor, the guest-cart mismatch
banner, compact cart, promotion/shipping interactions, and the global
free-shipping popup. The empty-cart pair used clean anonymous
browser state with zero items on both storefronts. The account pair used the
signed-out sign-in screen, then exercised the in-place registration toggle and
Flutter validation without creating a customer.

**Findings**

- [P1] Remaining route groups still lack rendered comparison
  Location: compact store, product and cart layouts; authenticated checkout,
  account and order views; transfer-request states; mismatch banner; and the
  global shipping popup.
  Evidence: matched comparisons now cover the transfer decision, desktop
  catalogue, desktop product structure, empty and populated desktop cart, open
  cart preview, and signed-out account. The remaining states listed above do
  not yet have matched captures.
  Impact: their typography, responsive spacing, imagery and interaction states
  remain visually unverified.
  Fix: capture both sites at matching desktop and mobile viewports, combine
  each pair, and run the comparison loop.

- [P2] Source account content links have no production destination
  Location: signed-out account support and registration terms.
  Evidence: the pinned source links to `/customer-service`,
  `/content/privacy-policy`, and `/content/terms-of-use`, but contains no
  customer-service route or portable Morrow policy content. The Flutter page
  intentionally renders honest text instead of dead or invented links.
  Impact: public sign-in and registration work, but these secondary destinations
  are not yet actionable.
  Fix: complete the real contact and policy routes under #20, then replace the
  text with the shared interactive-link treatment and rerun the matched pair.

**Required fidelity surfaces**

- Fonts and typography: the transfer hierarchy, catalogue title/card copy,
  product information stack, empty and populated-cart hierarchy, cart preview,
  and public account forms passed; other routes remain pending.
- Spacing and layout rhythm: the transfer's centered column and the catalogue's
  sidebar, 24px gutters, four-column medium grid, 32px row gap and card rhythm
  passed after scrollbar normalization. Product detail now matches the source
  24px inset, 300px side columns, 64px gallery gutters and 192px sticky offset.
  Empty cart matches the source's combined 32px content inset, centered vertical
  composition and footer position within three rendered pixels. Public account
  sign-in and registration match the source's 384px form, 240px desktop rail,
  44px inputs, 40px primary action, divider and help-block placement. The
  populated cart matches the two-column grid, 160px gap, table tracks, 96px
  thumbnail, 40px quantity control and source omission of the final-row divider.
  The 420px preview aligns to the header's 24px right gutter and reserves the
  source's 122px image track plus 16px content gap.
- Colors and visual tokens: transfer foreground, zinc-600 copy, gray-200
  borders, exact black primary actions, the cart's neutral quantity pill,
  red/rose errors and emerald success are source-mapped; other rendered routes
  remain pending.
- Image quality and asset fidelity: the transfer uses the exact source SVG. The
  catalogue uses merchant images from each backend with the source's `9:16`
  card ratio. The cart and preview use each backend's real product thumbnail at
  the source's 96px square size; cross-backend product photography is
  intentionally not compared.
- Copy and content: the transfer heading, paragraphs and actions now match the
  source exactly. Empty-cart copy and its interactive link also match. Morrow
  account membership copy, required markers and toggle punctuation match the
  source structure. The populated cart and preview retain the source labels and
  remove the invented success toast because the timed preview is the source's
  add feedback. Morrow branding, privacy-safe omission of the owner email, and
  the temporarily non-actionable content-link text are intentional product
  differences; other route copy remains pending.

**Full-view comparison evidence**

The source and implementation transfer pages, then the two catalogue pages,
were captured from the same in-app browser tab and emitted as matched pairs.
The transfer composition and controls align. The catalogue title, sidebar,
four-column grid, source aspect ratios and card spacing align after correction.
The product detail pair confirms the source column geometry and information
stack; product content and action controls differ with the two seed products.
The empty-cart pair confirms the source content inset, copy, vertical placement,
blue diagonal-arrow link and footer divider. The signed-out account pairs
confirm the sign-in and registration compositions, exact control rhythm,
password visibility affordance, toggle behavior, readable validation and shared
support layout. The populated-cart pair confirms matching heading rhythm, table
tracks, line controls, totals and checkout action. The post-add product pair
confirms the cart preview's panel placement, item layout, subtotal and 48px
primary action while the panel remains open for its five-second feedback window.

**Focused region comparison evidence**

No focused crop was necessary for the transfer, empty-cart, public-account or
populated-cart pages because the full-view captures kept their copy and actions
clearly readable. The open 420px cart panels were emitted as matched full-page
pairs at native density; their type, thumbnail, subtotal and action remained
large enough for focused inspection without a lossy crop. The footer,
navigation, product cards, filters, authenticated account forms and checkout
controls still require focused captures.

**Comparison history**

- Initial transfer comparison found P2 copy and typography drift: the intro was
  paraphrased, the primary action used zinc instead of source black, and the
  smaller body changed line wrapping. The copy, token and body size were fixed.
- The second transfer comparison found the content stack ten pixels too low.
  The image-to-heading and heading-to-body gaps were corrected.
- The final combined comparison found no actionable P0, P1 or P2 transfer-page
  difference. Residual two-to-three-pixel vertical variation is P3 and follows
  browser text rendering; the raster-width difference is the source scrollbar,
  not layout drift.
- The initial catalogue comparison exposed a P1 three-column grid and `11:14`
  cards caused by measuring the post-sidebar box. The implementation now uses
  Medusa's viewport breakpoints, four columns at 1280px, `9:16` catalogue cards,
  `11:14` featured cards and source-shaped title/price visibility. The final
  combined comparison found no remaining P0, P1 or P2 desktop-grid mismatch.
- The initial product comparison exposed P2 column/gutter drift and a missing
  source collection link. The final pair aligns the source 24px page inset,
  300px side columns, 64px gallery gutters, 192px sticky content position and
  30px/40px title treatment. Cross-backend product copy, imagery, and variant
  controls remain data differences rather than visual findings.
- A clean preview restart proved the initial blank empty-cart capture was stale
  preview state rather than a product defect. The first valid comparison exposed
  a P2 missing 8px inner inset and a gray horizontal-arrow button in place of
  Medusa's blue InteractiveLink. The final pair uses the 32px combined inset and
  reusable blue diagonal-arrow link with no remaining P0, P1 or P2 mismatch.
- The first settled account comparison exposed a P1 full-width, top-aligned form
  with no source AccountSupport section. The source shell, empty 240px signed-out
  rail, centered 384px form, typography and support divider were translated.
  A browser validation pass rejected a tightly constrained input experiment
  because it compressed error borders; the final dense 44px controls retain
  readable expanding errors. The sign-in/register pair has no remaining P0 or
  P1 mismatch. The missing real customer-service and policy destinations remain
  the explicit P2 above rather than dead links.
- The initial populated-cart comparison exposed P2 regular-weight headings, an
  Item label over the product-title track, a compressed quantity column, square
  quantity control, extra final-row divider and 14px actions. The final pair
  matches the source heading weights, table tracks, neutral pill and 16px/40px
  controls with no remaining P0, P1 or P2 desktop-cart mismatch.
- The initial cart-preview comparison exposed P2 viewport-edge anchoring,
  compressed thumbnail-to-copy spacing, a 40px instead of 48px primary action,
  an invented success toast and premature dismissal when the pointer was away.
  The final post-add pair aligns the panel to the header gutter, matches the
  source item grid and action size, and preserves the five-second feedback
  window. Cross-backend item content is an expected data difference.

**Implementation checklist**

- Capture the authenticated transfer-request form at desktop and compact
  widths, including idle, delivery-sent, delivery-pending and safe error states.
- Capture `/store` at compact width and with the shared footer visible; exercise
  sorting, option accordions and pagination in a browser that supports input.
- Capture product detail at compact width and exercise selected, unavailable,
  sold-out and add-to-cart feedback states against matched product fixtures.
- Capture populated cart at compact width and exercise promotion, shipping,
  line-removal and checkout actions against matching anonymous fixtures.
- Capture the public transfer page at `390 x 844` and verify the intentional
  full-width native adaptation remains usable.
- Capture signed-out account at compact width after the real customer-service,
  privacy-policy and terms routes are available under #20.
- Capture the remaining route and interaction states listed above.
- Compare each source/implementation pair together and fix every P0/P1/P2
  difference before changing the global result.

**Follow-up polish**

- Reassess the transfer page's residual P3 text-rendering variation only after
  a true equal-raster capture is available.

final result: blocked
