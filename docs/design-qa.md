# Storefront design QA

## Source truth

- Medusa DTC source commit:
  `19e8a6fbefea5a385e9502409908bfbebbecf526`.
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

The slice passes all 114 non-widget storefront tests, Flutter analysis and all
47 generated Dust checks. Localization validation has zero errors and five
inherited warnings. The live desktop form and success/failure regions were
inspected without overflow or console-visible runtime failure. The pinned DTC
source provides the help link but no matching customer return form, so this is
a source-structured capability check rather than a same-state raster claim.

## Open findings

- P2 — Repeat the verification success/failure capture against the live Medusa
  preview when its route is reachable, combine each same-state pair, and judge
  visible differences before declaring rendered parity.
- P2 — Continue compact and authenticated account-state comparisons from the
  storefront parity ledger.
- P2 — Complete same-state Review and order-confirmation comparisons.
- P1 — Add customer return-reason discovery and current-request visibility so
  exhausted quantities can be disabled before submission.
- P1 — Add the separate Admin return list, detail and processing workflow before
  claiming production return lifecycle parity.

## Result

The verification interaction, API boundary, local success/failure rendering,
and navigation pass. Customer return creation and server-side rejection pass
against the live local stack. Exact code-to-layout translation is implemented
where the pinned source owns a screen; broader storefront visual parity and a
complete return lifecycle are not claimed.

final result: blocked
