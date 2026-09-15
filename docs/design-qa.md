# Storefront design QA

## Source truth

- Medusa DTC source commit:
  `bd2441acc18359533758fbf4db5bc80129055d2e`.
- Verification route:
  `apps/storefront/src/app/[countryCode]/(main)/verify-account/page.tsx`.
- Verification component:
  `apps/storefront/src/modules/account/components/verify-account/index.tsx`.
- Registration state:
  `apps/storefront/src/modules/account/components/register/index.tsx`.
- Production preview: `https://next.medusajs.com/dk`.
- Prototype: Morrow at port `13001`, backed by the local API at port `3878`.

## Email-verification slice

The pinned source and Morrow use the same centered 384px content column, 32px
horizontal and 48px vertical page padding, uppercase semibold title, 16px
vertical rhythm, centered body copy, primary success action, and secondary
failure action. Morrow keeps its existing source-matched navigation and footer
around the route and replaces only the Medusa brand.

The local browser consumed a real database-backed capability, rendered the
success state, and navigated `Go to sign in` to `/account`. Reopening the
consumed link rendered the same invalid-or-expired state used for unknown and
expired capabilities. The capability never appeared in the public Dust state.

The live Medusa preview was captured successfully for the shared Store shell
earlier in the pass. When the verification route was requested for the final
same-state pair, the in-app browser proxy returned
`ERR_PROXY_CONNECTION_FAILED`. The component source remained available from
the pinned local clone, but source code is not a substitute for a same-state
rendered comparison.

## Customer-return request slice

The pinned order-detail source keeps `Returns & Exchanges` in the compact
`Need help?` block. Morrow preserves that hierarchy and turns the link into an
authenticated, API-backed expansion rather than inventing a separate route.
Only completed or captured orders expose the control. The form freezes the
owned order items, requires at least one selected quantity, accepts an optional
note, prevents duplicate submission while pending, and reports only
display-safe server failures.

Authenticated browser QA created and captured order display id `1`, submitted
one Essential T-Shirt with the note `Customer return browser QA`, and received
return request `#1`. The database retained exactly one request and one item for
the signed-in customer. Reopening the form and requesting the already exhausted
quantity returned `These items can no longer be returned.` and did not create a
second row. This verifies the success, ownership, quantity and atomic rejection
boundaries against the real API; it does not prove an Admin decision workflow.

The slice passes all 120 non-widget storefront tests, Flutter analysis and all
47 generated Dust checks. Localization validation has zero errors and five
inherited warnings. The live desktop form and success/failure regions were
inspected without overflow or console-visible runtime failure. The pinned DTC
source provides the help link but no matching customer return form, so this is
a source-structured capability check rather than a same-state raster claim.

The follow-up reason slice exposes five active merchant reasons through the
public Store API and keeps the reason optional, matching Medusa's request
contract. Authenticated browser QA selected the completed order item, observed
the dedicated `OrderReturnReasonField`, and changed its generated ViewModel
state to `Changed my mind`. The selected label remained visible in the
expanded form. No helper method returns a Widget; loading, empty, failure and
loaded states belong to the dedicated widget class.

The remaining-quantity slice now returns Medusa's delivered, requested,
received and dismissed quantities on every Store order item. The return form
uses their returnable difference as its maximum and omits exhausted items.
Authenticated reload QA against order display id `1` showed `This order has no
items left to return.` with no checkbox, quantity, reason, note or submit
control. No additional return was submitted. The simplified lifecycle has now
been replaced: only quantities in active fulfillments with a real delivery
timestamp count as delivered or returnable.

## Store fulfillment-status slice

The pinned DTC `OrderDetails` component labels `order.fulfillment_status` as
`Order status`; it does not render Dust's separate business order status or a
tracking panel. Morrow now follows that exact source boundary. A standalone
Store enum keeps the customer contract separate from Admin, and direct SQLx
order projections derive partial and full fulfillment, shipment and delivery
from active fulfillment item quantities.

Live QA reused the fresh 59-migration return-history database. The authenticated
Admin API created and delivered the existing order's fulfillment, after which
the authenticated Store API returned `fulfillment_status: delivered` and one
delivered unit. The release-mode account order page rendered `Order status:
Delivered` at the default viewport and at `390 × 844`; the compact screenshot
showed no overflow and the browser console contained no warnings or errors.
The full 467-test server suite, 128 non-widget Store tests, both analyzers and
normal plus SQLx Dust checks pass.

## Customer return-history slice

The pinned DTC order detail has no customer return-history component. Its
`Help` component renders `Contact` and `Returns & Exchanges`, both linked to
`/contact`. Morrow preserves the `Need help?` placement and adds its explicit
customer-owned history immediately below it. This is a secure Dust extension,
not a same-state Medusa raster-parity claim.

Live QA used a fresh database created by all 59 SQLx migrations. Supported
Store and Admin APIs created an authenticated customer, a completed and
captured order, and requested return `#1`; the generated history endpoint then
returned exactly one customer-owned row. No historical rows were patched by
hand.

The authenticated order-detail route rendered `Return history`, `Return #1`,
`Requested`, the localized request date, and `1 item(s)` at both the default
desktop viewport and `390 × 844`. A hard reload retained the secure session,
reloaded the generated history request, and rendered the same row. The browser
console contained no warnings or errors. The implementation passes all 127
non-widget storefront tests, Flutter analysis, and all 50 generated Dust
checks; no widget test was added.

## Admin return receipt slice

The pinned Admin source has no standalone Returns page. Order detail queries
requested returns and exposes `Receive return` from the Summary, so Morrow uses
that same hierarchy. The separate Admin contract and generated client list only
merchant-safe return fields through the shared Dio bearer, while the server
keeps both a route-level guard and authenticated handler extraction.

Live Admin QA against requested return `#1` rendered the Summary action and the
receipt dialog with intact, damaged and notification inputs. Cancel closed the
dialog without consuming the reusable fixture. Server tests submit the actual
command and prove that every item is validated before writes, partial and final
statuses are derived atomically, intact managed units are restored to stock,
and damaged or unmanaged units are not. Invalid mixed receipts roll back both
return progress and inventory.

The UI slice adds no widget test and no helper method returning `Widget`; each
subtree is a concrete widget class. All 82 non-widget Admin tests and all 386
server tests pass. Admin and server analyzers, normal Dust checks and SQLx Dust
checks are clean.

## Open findings

- P2 — Repeat the verification success/failure capture against the live Medusa
  preview when its route is reachable, combine each same-state pair, and judge
  visible differences before declaring rendered parity.
- P2 — Continue compact and authenticated account-state comparisons from the
  storefront parity ledger.
- P2 — Complete same-state Review and order-confirmation comparisons.
- P1 — Add external payment-provider refund adapters before claiming a complete
  production refund lifecycle; labels and exchanges remain separate.

## Result

The verification interaction, API boundary, local success/failure rendering,
reason selection, and navigation pass. Customer return creation and
server-side rejection pass against the live local stack. Exhausted quantities
are also disabled before submission. Customer return history passes desktop,
compact and reload browser QA as an explicit extension beneath the pinned
source's help block. Exact code-to-layout translation is implemented where the
pinned source owns a screen. Store order status and return eligibility now use
the real fulfillment lifecycle. Admin requested-return receipt, intact
inventory restoration and independent manual-payment refunds pass, while
broader storefront visual parity and external refund-provider support are not
claimed.

final result: partial
