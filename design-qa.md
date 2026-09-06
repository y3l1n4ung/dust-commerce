# Storefront design QA

Source visual truth paths:

- Pinned source: `/private/tmp/dtc-starter.9KjRyK/source/apps/storefront/src/app/[countryCode]/(main)/order/[id]/transfer/[token]/page.tsx`
- Rendered reference: `https://next.medusajs.com/dk/order/order_qa/transfer/demo-capability?qa=matched-final`

Implementation screenshot path: in-app browser capture of
`http://127.0.0.1:13001/order/order_qa/transfer/demo-capability?qa=matched-final`.
The browser capture is retained in the task evidence rather than exported into
the repository.

Viewport: the matched desktop capture used the same in-app browser tab. The
reference raster was `1265 x 712`; the implementation raster was `1280 x 720`.
The reference's visible scrollbar produced the small raster-size difference.
Compact `390 x 844` transfer and authenticated account-form captures remain.

Pixel dimensions, CSS size, and density normalization: both captures used the
in-app browser's default CSS viewport and density. Comparison normalized the
implementation by the reference-to-implementation ratio (`1265 / 1280`); no
finding was filed from the scrollbar or raster-size difference.

State: the public transfer page used the same `order_qa`, unused demo
capability, English locale, light theme and idle decision state. Remaining
global QA covers `/store` with the shared footer visible, authenticated
`/checkout` with a saved address available, authenticated `/account` with a
completed profile, saved addresses and recent orders,
`/account/orders/details/:id`, the authenticated transfer-request form and its
success/error states, the profile password editor, the guest-cart mismatch
banner, and the global free-shipping popup.

**Findings**

- [P1] Remaining route groups still lack rendered comparison
  Location: Medusa DTC and Morrow storefront views outside the public transfer
  decision route.
  Evidence: the Mac and in-app browser are available, and the transfer decision
  page now has a matched comparison. The other states listed above do not yet
  have matched desktop and compact captures.
  Impact: their typography, responsive spacing, imagery and interaction states
  remain visually unverified.
  Fix: capture both sites at matching desktop and mobile viewports, combine
  each pair, and run the comparison loop.

**Required fidelity surfaces**

- Fonts and typography: the transfer heading, 16px body hierarchy, line wraps
  and 18px actions passed; other routes remain pending.
- Spacing and layout rhythm: the transfer's 40% centered desktop column,
  section gaps, dividers and action row passed within three rendered pixels
  after scrollbar normalization; other routes remain pending.
- Colors and visual tokens: transfer foreground, zinc-600 copy, gray-200
  borders, exact black primary action, red/rose errors and emerald success are
  source-mapped; other rendered routes remain pending.
- Image quality and asset fidelity: the transfer uses the exact `280 x 181`
  MIT-licensed source SVG rather than a drawn approximation; other visible
  assets remain pending.
- Copy and content: the transfer heading, paragraphs and actions now match the
  source exactly. Morrow branding and privacy-safe omission of the owner email
  are intentional product differences; other route copy remains pending.

**Full-view comparison evidence**

The source and implementation transfer pages were captured from the same
in-app browser tab and emitted together for comparison. Their composition,
hierarchy, copy, illustration, dividers and controls align after the final
iteration. Remaining route groups have no new full-view evidence in this pass.

**Focused region comparison evidence**

No focused crop was necessary for the transfer page because its full-view
capture kept the heading, body copy, SVG and both actions clearly readable. The
footer, navigation, product cards, filters, cart preview, account form and
checkout controls still require focused captures.

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

**Implementation checklist**

- Capture the authenticated transfer-request form at desktop and compact
  widths, including idle, delivery-sent, delivery-pending and safe error states.
- Capture the public transfer page at `390 x 844` and verify the intentional
  full-width native adaptation remains usable.
- Capture the remaining route and interaction states listed above.
- Compare each source/implementation pair together and fix every P0/P1/P2
  difference before changing the global result.

**Follow-up polish**

- Reassess the transfer page's residual P3 text-rendering variation only after
  a true equal-raster capture is available.

final result: blocked
