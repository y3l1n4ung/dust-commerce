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
| `layout/templates/nav` | shared storefront shell | partial in #19; nav/menu/cart count work, footer remains |
| `home/components/hero` | home hero | implemented in #19 |
| `featured-products/product-rail` | featured product grid | partial in #19; collection rails wait on #18 |
| `products/components/product-preview` | product card | implemented in #19 |
| `store/templates` | catalogue | partial in #19; dedicated store filters and paging remain |
| `products/templates` | product detail route | implemented in #22; source-ordered mobile and sticky desktop composition |
| `products/components/product-actions` | variant state and add to cart | implemented in #22, including `v_id`, unavailable combinations and sticky mobile actions |
| `products/components/related-products` | API-backed recommendations | implemented in #22 with loading, empty, failure and success states |
| `layout/components/cart-dropdown` | cart preview | queued in #21 |
| `cart/templates` | cart route | partial in #21; responsive source layout, empty state, line controls, promotion UI and authoritative totals implemented; sign-in prompt, header preview and checkout handoff remain |
| `account/templates` | account shell and session | queued in #26 |
| `checkout/templates` | checkout and payment | queued in #28 |
| `order/templates` | confirmation and order details | queued in #20 and #28 |
| categories and collections routes | product organisation | queued in #18 and #24 |

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

The Medusa-only `ProductOnboardingCta` is intentionally excluded. It appears
only when a private admin-setup cookie is present and links to Medusa's local
admin onboarding flow; it is not a customer storefront capability or a valid
Morrow production destination.

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
