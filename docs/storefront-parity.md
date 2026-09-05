# Medusa DTC storefront parity

The implementation target is the customer-facing storefront in
[medusajs/dtc-starter](https://github.com/medusajs/dtc-starter), pinned at
`19e8a6fbefea5a385e9502409908bfbebbecf526`. React and Next.js constructs are
translated into native Flutter and Dust patterns; the application talks only
to the dust-commerce API. Visual tokens are pinned to
`@medusajs/ui-preset@2.20.1`, the version used by that source revision.

Progress is tracked in [GitHub issue #29](https://github.com/y3l1n4ung/dust-commerce/issues/29)
and the `Medusa DTC storefront parity` milestone.

## Source-to-Dust map

| Medusa source | Flutter/Dust owner | Status |
| :--- | :--- | :--- |
| `layout/templates/nav` and `footer` | shared storefront shell | implemented in #19 with nav, menu, cart count, API-backed footer taxonomy, Morrow branding, and only `Powered by dust`; rendered QA remains |
| `home/components/hero` | home hero | implemented in #19 |
| `featured-products/product-rail` | featured product grid | implemented in #18 with source-ordered, API-backed collection rails; rendered QA remains |
| `products/components/product-preview` | product card | implemented in #19 |
| `store/templates` | catalogue | partial in #18 and #19; source sorting, 12-item paging, stable option-value filtering, and optional filter discovery implemented; rendered QA remains |
| `products/templates` | product detail route | implemented in #22; source-ordered mobile and sticky desktop composition |
| `products/components/product-actions` | variant state and add to cart | implemented in #22, including `v_id`, unavailable combinations and sticky mobile actions |
| `products/components/related-products` | API-backed recommendations | implemented in #22 with loading, empty, failure and success states |
| `layout/components/cart-dropdown` | cart preview | implemented in #21 with hover, timed add feedback, live removal, subtotal and empty state |
| `cart/templates` | cart route | implemented in #21, #26 and #28 with responsive source layout, empty state, line controls, promotion UI, authoritative totals, session-aware sign-in prompt and checkout handoff; rendered QA remains |
| `account/templates` | account shell and session | implemented in #20 and #26 with secure session, source-exact four-part overview completion, saved-address count, latest-five order links, profile name/phone/billing/password editing, API-backed address book, source-shaped navigation, order list and guarded order detail; rendered QA remains |
| `checkout/templates` | checkout and payment | implemented in #28 and #20 with real address, region-scoped saved-address selection, delivery, manual-payment, review and confirmation steps; rendered QA remains |
| `order/templates` | confirmation and order details | partial in #20, #26 and #28; confirmation, authenticated order list, source-shaped cards and guarded frozen order detail metadata, lines, delivery and totals implemented; contact, transfer and return flows remain |
| `regions` store API | account and checkout country selection | implemented with explicit SQLx response allowlists; address-book selectors use active backend regions rather than hard-coded countries |
| categories and collections routes | product organisation | implemented in #18 with real API metadata, filtering, hierarchy, sorting and paging; exact nested category paths wait on `dust#542`, rendered QA remains |

## Theme and selection map

These values come from the light tokens in
`@medusajs/ui-preset@2.20.1/src/theme/tokens/colors.ts`. Flutter uses semantic
names so components do not invent close-but-different greys.

| Medusa source token or class | Exact source value | Flutter owner |
| :--- | :--- | :--- |
| `bg-ui-bg-base` | `#FFFFFF` | `StoreColors.base` |
| `bg-ui-bg-subtle` | `#FAFAFA` | `StoreColors.subtle` |
| account `bg-gray-50` | `#F9FAFB` | `StoreColors.neutral50` |
| `border-ui-border-base` | `#E4E4E7` | `StoreColors.border` |
| `border-ui-border-interactive` | `#3B82F6` | `StoreColors.interactive` |
| `text-ui-fg-base` | `#18181B` | `StoreColors.foreground` |
| `text-ui-fg-subtle` | `#52525B` | `StoreColors.foregroundSubtle` |
| `text-ui-fg-muted` | `#71717A` | `StoreColors.foregroundMuted` |
| `rounded-rounded` | `8px` | product image and option radius |
| `small` breakpoint | `1024px` | product and cart desktop composition |
| `content-container` | `1440px`, `24px` inline padding | product content bounds |

`OptionSelect` is copied behaviorally rather than replaced by Material chips:
each value is an equal-width 40px rectangle on the subtle background, the
selected value changes only to the interactive border, and an unselected
hover receives the Medusa card-rest shadow treatment. Invalid combinations are
disabled by the product state before an interaction reaches the API.

The store refinement sidebar also follows Medusa's `OptionsPicker`: filters
come from `/store/product-options`, every group starts expanded, selections use
stable value identifiers in repeated `optionValueIds` query keys, and changing
a selection removes the current page. Option discovery is intentionally
non-fatal, while collection and category routes retain incoming selections but
hide the picker exactly as the source templates do.

The Medusa-only `ProductOnboardingCta` is intentionally excluded. It appears
only when a private admin-setup cookie is present and links to Medusa's local
admin onboarding flow; it is not a customer storefront capability or a valid
Morrow production destination.

The shared footer preserves the source structure and limits: the Morrow brand,
up to six API-backed root categories with direct children, up to six
collections, project-resource links, a current-year copyright line, and the
requested lowercase `Powered by dust` attribution. Category and collection
discovery fail independently so footer data cannot take down working page
content.

Medusa declares categories as a catch-all route so a full hierarchical handle
stays readable (`/categories/clothing/shirts`). Dust Flutter 0.1.4 currently
supports one segment per typed path parameter, so the generated route preserves
the same handle as `/categories/clothing%2Fshirts`. Exact parse-and-restore
support is tracked upstream in
[`dust#542`](https://github.com/y3l1n4ung/dust/issues/542); generated files are
not hand-edited around that limitation.

## Customer session boundary

Account responses and UI state are explicit field allowlists. They do not
inherit from database or domain models, so adding an internal field cannot
silently widen the storefront API. Bearer credentials are stored as one atomic
secure-storage value, attached only by Dio, and excluded from generated method
parameters and ViewModel state. The `/account/orders` route uses a typed Dust
guard and redirects a signed-out deep link to the shared `/account` sign-in
screen. The profile and address routes use the same guard. Address and order
state is cleared whenever the authenticated customer identity changes, and
in-flight responses from a previous identity are ignored. Checkout form state
is cleared on the same boundary, while authenticated customers can copy a
saved address into the editable form only when its country belongs to the
cart's active region. Order detail keeps its loaded order and failure as Dust
`Option` values, and a missing or foreign order receives the same unavailable
state so the UI does not disclose whether another customer's id exists.
Password rotation completes the TODO in the pinned Medusa profile source: it
requires the current secret, writes a fresh Argon2id PHC value with
compare-and-swap protection, atomically revokes every session, and signs the
Flutter customer out. The confirmation value never crosses the API boundary.
The overview loads address and order capabilities independently, does not
report unknown data as zero, computes the same email/name/phone/default-billing
quarters as Medusa, and links at most the five newest server-ordered purchases.
Order-history absence and failure use Dust `Option` state rather than nullable
display strings.

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
The current rendered comparison gate is recorded in `design-qa.md`.
