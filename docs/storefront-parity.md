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
| `cart/templates` | cart route | partial in #21 and #26; responsive source layout, empty state, line controls, promotion UI, authoritative totals and session-aware sign-in prompt implemented; checkout handoff remains |
| `account/templates` | account shell and session | partial in #26; register, sign in, sign out, secure restore, overview, navigation and order list implemented; profile and address editing remain |
| `checkout/templates` | checkout and payment | queued in #28 |
| `order/templates` | confirmation and order details | partial in #26; authenticated order list and source-shaped cards implemented; confirmation, detail, transfer and return flows remain in #20 and #28 |
| categories and collections routes | product organisation | implemented in #18 with real API metadata, filtering, hierarchy, sorting and paging; exact nested category paths wait on `dust#542`, rendered QA remains |

## Theme and selection map

These values come from the light tokens in
`@medusajs/ui-preset@2.20.1/src/theme/tokens/colors.ts`. Flutter uses semantic
names so components do not invent close-but-different greys.

| Medusa source token or class | Exact source value | Flutter owner |
| :--- | :--- | :--- |
| `bg-ui-bg-base` | `#FFFFFF` | `StoreColors.base` |
| `bg-ui-bg-subtle` | `#FAFAFA` | `StoreColors.subtle` |
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
screen.

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
The current rendered comparison gate is recorded in `design-qa.md`.
