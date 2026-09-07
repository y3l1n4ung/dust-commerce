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
- Pinned promotion source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/checkout/components/discount-code/index.tsx`
- Rendered promotion reference: `https://next.medusajs.com/dk/cart?qa=promotion-shipping-source`
- Pinned public-account sources: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/account/templates/account-layout.tsx`, `login-template.tsx`, and `components/{login,register}/index.tsx`
- Rendered public-account reference: `https://next.medusajs.com/dk/account?qa=account-signed-out`
- Pinned checkout sources: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/modules/checkout/components/{addresses,shipping,payment,review}/index.tsx`
- Rendered checkout reference: `https://next.medusajs.com/dk/checkout?step=delivery`

Implementation screenshot paths: in-app browser captures of the transfer route
`http://127.0.0.1:13001/store?qa=store-grid-final`, and
`http://127.0.0.1:13001/products/shorts?qa=product-audit`, and
`http://127.0.0.1:13001/cart?qa=cart-after-restart`, and
`http://127.0.0.1:13001/cart?qa=populated-cart-restarted`, and
`http://127.0.0.1:13001/products/shorts?v_id=var_shorts_s`, and
`http://127.0.0.1:13001/account?qa=account-register-local`, and
`http://127.0.0.1:13001/cart`, and
`http://127.0.0.1:13001/checkout?step=review`, and
`http://127.0.0.1:13001/checkout?step=delivery`. The browser captures
are retained in the task evidence rather than exported into the repository.

Viewport: the matched desktop captures used the same in-app browser surface. The
reference raster was `1265 x 712`; the implementation raster was `1280 x 720`.
The reference's visible scrollbar produced the small raster-size difference.
Compact `390 x 844` transfer and authenticated account-form captures remain.
The promotion form comparison used the same `736 x 864` browser surface for
both storefronts. Guest checkout address and initial delivery comparisons also
used that same `736 x 864` surface. The desktop checkout comparison used an
equal `1280 x 720` CSS viewport; the final implementation capture came from an
isolated headless Chrome profile because the interactive Mac session locked.
The compact collection grid and footer pair used equal `390 x 844` CSS
viewports. The final menu interaction pass returned to the in-app browser after
it became available.

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
comparable. The compact collection pair covered the two-column grid through the
shared footer; source and local taxonomy counts differ because they use separate
merchant data. The live side-menu comparison additionally covered the inset
blurred panel, source labels, close button, Escape dismissal and Store
navigation. Remaining global QA covers the product route at compact width and
in selected/out-of-stock states,
`/store` compact sorting, option and paging controls, authenticated
`/checkout` with a saved address available, authenticated `/account` with a
completed profile, saved addresses and recent orders,
`/account/orders/details/:id`, the authenticated transfer-request form and its
success/error states, the profile password editor, the guest-cart mismatch
banner, compact cart, shipping interactions, the source promotion-success
state, and the global free-shipping popup. Promotion QA now covers the
source-matched open form plus
local success, recalculation, removal and safe-error states. The live source
returned a generic production Server Components error for the tested code, so
a rendered source success state is still unavailable. The empty-cart pair used
clean anonymous browser state with zero items on both storefronts. The account pair used the
signed-out sign-in screen, then exercised the in-place registration toggle and
Flutter validation without creating a customer. Local free-shipping QA used the
seeded server rule at `EUR 100`: below-target, unlocked, faded, restored and
session-dismissed states were captured. The live source cart exposed no
conditional zero-cost shipping rule, so a matched popup pair remains pending.
The guest checkout pair used equivalent complete addresses and one cart line.
The address form and initial delivery composition were compared together. The
local journey then reached Review through Standard delivery and Manual Payment
without placing an order. The live reference failed its Server Components
mutation when Standard delivery was selected, so it could not render payment
or review; those local states were checked against the pinned source structure
rather than claimed as a successful live pair. Desktop QA repeated the address
step at `1280 x 720`, then advanced to Delivery and hard-reloaded the route. The
collapsed shipping/contact summary and selected checkout step survived from
the server cart. A local authenticated account also rendered the region-scoped
saved-address selector; the public reference was not mutated to create an
account, so authenticated head-to-head evidence remains open.

**Findings**

- [P1] Remaining route groups still lack rendered comparison
  Location: compact store controls, product and cart layouts; checkout authenticated,
  payment, review and confirmation states; account and order
  views; transfer-request states; mismatch banner; and the global shipping
  popup.
  Evidence: matched comparisons now cover the transfer decision, desktop
  catalogue, compact collection grid/footer/menu, desktop product structure,
  empty and populated desktop cart, open cart preview, signed-out account, and
  the open promotion form. The remaining states listed above do not yet have
  matched captures.
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
  passed after scrollbar normalization. The compact collection uses the
  source's two-column flow, natural card heights and two-column taxonomy footer;
  its inset menu follows the source width, blur, radius and 24px content inset.
  Product detail now matches the source
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
  add feedback. The promotion form retains the source's blank input, compact
  row, applied heading, code badge, visible value and post-success open state.
  Morrow branding, privacy-safe omission of the owner email, and
  the temporarily non-actionable content-link text are intentional product
  differences. Guest checkout matches the source field order, required
  markers, billing toggle, desktop summary hierarchy, delivery labels and
  payment/review hierarchy. The
  local delivery prompt intentionally corrects the source typo from "you
  order" to "your order"; other route copy remains pending.

**Full-view comparison evidence**

The source and implementation transfer pages, then the two catalogue pages,
were captured from the same in-app browser tab and emitted as matched pairs.
The transfer composition and controls align. The catalogue title, sidebar,
four-column grid, source aspect ratios and card spacing align after correction.
The equal-width compact collection pair confirms the two-column grid, wrapped
card metadata and responsive footer. A final in-app browser pass confirms the
source-shaped menu, both close paths and navigation to `/store`.
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
The promotion pair confirms the compact blank input and secondary action at an
identical viewport. Local interaction captures additionally prove apply,
percentage disclosure, recalculation, removal and safe failure rendering.
The checkout pair confirms the compact address geometry, country placeholder,
billing toggle, Continue action, step dividers and initial delivery state. The
local server-backed journey additionally proves Standard delivery, the
API-listed Manual Payment choice and Review with authoritative totals. It
deliberately stopped before Place order. Manual Payment is retained on the
server-owned cart; a hard reload at `/checkout?step=review` restored the same
URL, collapsed payment summary and active Review action. A later exact-source
pass loaded Medusa's Payment route directly and compared the same selected
Manual Payment state beside Morrow at the same browser surface. The radio card,
interactive border, icon, spacing and black action treatment align. The source
still lacked a completed address and delivery state, so no whole-page Review
match is asserted. After adding the server-side delivery guard, the valid local
path returned from Payment to Review with the same collapsed summaries and
`Place order` action; no local UI changed. A fresh Medusa Review capture still
lacked completed shipping state, so this regression pass does not add a
same-state whole-page parity claim. A subsequent fresh local release-mode
purchase reached the confirmation route and retained it through reload. Source
inspection then corrected the receipt to its 64px table rows, quantity/unit and
line price stack, short display number, parenthesized delivery cost, and
provider amount/time payment details. The matching live Medusa cart was reset,
but its Espresso Cup add mutation remained indefinitely in `Loading...`, so a
same-state confirmation screenshot could not be produced and no visual match
is asserted. The desktop pass confirms the
complete back label, 24px semibold summary heading, source-spaced dividers, right-aligned
quantity/unit price, and final totals rule. A browser-only CORS failure on the
new address PUT was found and fixed before the successful Delivery transition;
hard reload then reproduced the same collapsed address state.

**Focused region comparison evidence**

No focused crop was necessary for the transfer, empty-cart, public-account or
populated-cart pages because the full-view captures kept their copy and actions
clearly readable. The open 420px cart panels were emitted as matched full-page
pairs at native density; their type, thumbnail, subtotal and action remained
large enough for focused inspection without a lossy crop. Compact collection
cards, footer columns and the side menu were readable in their full-page
captures. The selected Manual Payment control was emitted in a same-surface
pair after both implementations loaded their provider list. Store filters,
authenticated account forms and remaining checkout controls still require
focused captures.

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
- The first compact collection pass exposed bottom-overflow stripes on wrapped
  product names and a one-column footer caused by fixed card heights and a
  desktop-sized column gap. Natural-height cards and the source compact footer
  spacing removed both defects. The side-menu pass then replaced the default
  opaque drawer with the source's inset translucent panel, restored the `Store`
  label, matched its responsive minimum width, and verified button and Escape
  dismissal plus Store navigation in the live browser.
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
- The initial promotion comparison exposed a P2 full-width local input, visible
  placeholder, taller field, hidden promotion value and form dismissal after
  success. The final open-form pair matches the source's compact 40px blank
  field and action. Local browser QA applied `WELCOME10`, displayed
  `WELCOME10 (10%)`, recalculated `EUR 1.50` to `EUR 3.00` when quantity changed,
  removed it, and rendered an invalid-code error. Source success comparison
  remains unavailable because the live reference returns a generic production
  Server Components error for the submitted code.
- Source inspection found that the free-shipping popup holds its green unlocked
  state for one second and then fades for 500ms; the local popup previously
  disappeared immediately. Browser QA now proves the server-owned `EUR 100`
  boundary, remaining amount, unlocked hold/fade, reappearance below the
  threshold and cart-session dismissal. The same pass fixed the quantity `10`
  wrapping inside its source-sized 56px control. A matched rendered popup pair
  still needs a source cart with a conditional free-shipping price.
- The initial checkout comparison exposed a P2 preselected country, combined
  company/apartment value, Material-scale fields, oversized gaps, sticky local
  attribution and incorrect step spacing. The corrected address state matches
  the source's field order, blank country placeholder, 44px controls, 14px
  rhythm, billing toggle and in-flow `Powered by dust` placement at `736 x
  864`. Company and apartment now remain independent through the real API and
  frozen order snapshot. Standard delivery and Manual Payment reach Review
  locally; the source delivery mutation fails before those live states.
- The first desktop checkout retry exposed a production CORS omission: direct
  tests passed, but the browser could not preflight the new cart-address PUT.
  The explicit storefront policy now includes PUT with preflight coverage. The
  corrected `1280 x 720` render also fixes the truncated back label, oversized
  cart heading, excess divider spacing, and non-source line-price layout. A
  hard reload at Delivery preserves the collapsed server-owned address step.
- Source inspection then exposed a functional reload gap that screenshots did
  not: the pinned Payment component derives its selected provider from the
  cart's pending payment session, while Flutter held `manual` only in memory.
  The generated client now selects an allowlisted server session through the
  guarded cart route, checkout refuses an unselected provider, and a settled
  release-mode browser pass proves Review survives a hard reload with the
  source-exact `Place order` action. A same-state rendered pair remains blocked
  by the live reference's failing Standard-delivery mutation.
- The checkout transaction now rejects a missing shipping-method snapshot
  before stock reservation or order creation. Targeted and full server/client
  suites prove the bypass returns `422` without changing stock or order count;
  the normal release-mode browser path still reaches Review. Because this is a
  backend guard with no UI delta and the live source remains in an incomplete
  shipping state, no new visual parity result is claimed.
- A fresh database and release-mode browser purchase proved the complete local
  cart → address → delivery → payment → review → confirmation path, including
  a database-owned display number and an API-backed provider amount/time
  receipt that survives route reload. The final top and detail captures were
  inspected at `1280 x 720`. Medusa's source code supplied the exact component
  contract, but its live add-to-cart mutation stalled after the previous cart
  was cleared, so same-state confirmation comparison remains pending.

**Implementation checklist**

- Capture the authenticated transfer-request form at desktop and compact
  widths, including idle, delivery-sent, delivery-pending and safe error states.
- Capture `/store` at compact width and exercise sorting, option accordions and
  pagination; compact collection, shared-footer and side-menu QA now pass.
- Capture product detail at compact width and exercise selected, unavailable,
  sold-out and add-to-cart feedback states against matched product fixtures.
- Capture populated cart at compact width and exercise shipping, line-removal
  and checkout actions against matching anonymous fixtures.
- Capture authenticated checkout against a non-destructive reference account;
  retry the payment/review pair when the reference delivery
  mutation works, then capture confirmation without placing an unintended
  reference order.
- Capture a source promotion success state when the reference has a valid code,
  then compare it with the verified local applied and removal states.
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

## Admin product media slice

Source: Medusa commit \`bda24b9725ac697ec5e8f706b503013e20babf12\`,
\`product-create-details-media-section.tsx\`, and
\`upload-media-form-item.tsx\`. Prototype: Morrow Admin on port \`13002\`
with API port \`3878\`.

Medusa reference and Morrow implementation were captured in the same in-app
browser at \`505 x 583\` and combined before review. The official 16:9 reference
is letterboxed at this viewport, so structural parity is verified; pixel parity
is not claimed.

- Pass: Media follows Description and precedes Variants.
- Pass: optional label, upload action, supported formats, size policy, ordered
  rows, thumbnail action and delete action follow pinned source.
- Pass: upload, cancel cleanup, attachment, storefront delivery and attached-file
  deletion guard are real API behavior, not visual placeholders.
- Open P1: post-create media mutation remains.
- Open P1: multi-node object storage and abandoned-stage cleanup remain.
- Open P2: obtain an unletterboxed source capture for pixel-diff QA.

Admin product media result: passed

## Admin product variant-detail slice

Source visual truth: Medusa `2.20.1` at pinned commit
`bda24b9725ac697ec5e8f706b503013e20babf12`, specifically
`packages/admin/dashboard/src/routes/product-variants/product-variant-edit/`
and `product-edit-variant-form.tsx`. The source was run locally on port `19000`
against its isolated demo catalogue.

Implementation: Morrow Admin on port `13002`, backed by the Dust API on port
`3878` and a fresh migrated QA database. Both drawers were captured at equal
`1280 x 720` CSS viewports and combined into one `2560 x 720` comparison at
`/private/tmp/dust-commerce-admin-variant-qa-20260907/variant-edit-comparison-final.png`.

State: light theme, authenticated product detail and the `M / Black` variant
drawer. Source and implementation use different merchant SKU prefixes; this is
a catalogue-data difference, not layout drift.

**Findings**

- No actionable P0, P1 or P2 variant-drawer difference remains in the combined
  first-fold comparison or the matched inventory and attribute inspections.
- Broader Admin and storefront parity findings remain open, so the repository's
  global QA result remains blocked.

**Required fidelity surfaces**

- Fonts and typography: heading, label, optional-marker and hint hierarchy pass.
- Spacing and layout rhythm: 560px inset drawer, sticky header/footer, field
  cadence, dividers and scroll behavior pass.
- Colors and visual tokens: neutral inputs, overlay, borders, black actions and
  compact blue inventory switch pass.
- Image quality and asset fidelity: no product imagery belongs inside this
  drawer; surrounding page imagery still needs the matched full-view capture.
- Copy and content: Material, ordered options, SKU/EAN/UPC/Barcode, both exact
  inventory hints and all seven attribute controls match the source hierarchy.

**Full-view comparison evidence**

The equal-size full views were emitted as one comparison. Drawer edges, header,
first four fields, first divider, inventory heading and footer align without an
actionable mismatch.

**Focused region comparison evidence**

No crop was required. Scrolling each live drawer exposed the policies and full
attribute section at readable native density.

**Comparison history**

- The first comparison found a flush 520px drawer, reversed option order,
  missing fields, boxed policies and mismatched copy.
- The final implementation uses the source's 560px inset geometry, database
  option rank, complete generated contract, compact policies and searchable
  250-country selector.
- Browser QA searched for Denmark, saved the variant, observed `Variant
  updated.`, reopened the drawer and confirmed the server-backed value.

**Implementation checklist**

- Keep the combined evidence with this task; temporary QA rasters are not
  committed to the product repository.
- Continue with the next feature slice only after this stacked branch is
  reviewed.

Variant-detail slice result: passed

final result: blocked
