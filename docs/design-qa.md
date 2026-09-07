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

## Open findings

- P2 — Repeat the verification success/failure capture against the live Medusa
  preview when its route is reachable, combine each same-state pair, and judge
  visible differences before declaring rendered parity.
- P2 — Continue compact and authenticated account-state comparisons from the
  storefront parity ledger.
- P2 — Complete same-state Review and order-confirmation comparisons.

## Result

The verification interaction, API boundary, local success/failure rendering,
and navigation pass. Exact code-to-layout translation is implemented. Final
same-state Medusa rendered comparison remains blocked by the reference preview
connection failure, so broader storefront visual parity is not claimed.

final result: blocked
