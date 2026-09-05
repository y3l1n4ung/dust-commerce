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
| `products/templates` | product detail route | partial in #22; source-ordered info, gallery, tabs and actions work; related products and sticky columns remain |
| `products/components/product-actions` | variant state and add to cart | partial in #22; combinations, stock state, `v_id`, price and add-to-cart work; sticky mobile actions remain |
| `layout/components/cart-dropdown` | cart preview | queued in #21 |
| `cart/templates` | cart route | partial in #21; persistence and mutations remain |
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
| `small` breakpoint | `1024px` | product desktop composition |
| `content-container` | `1440px`, `24px` inline padding | product content bounds |

`OptionSelect` is copied behaviorally rather than replaced by Material chips:
each value is an equal-width 40px rectangle on the subtle background, the
selected value changes only to the interactive border, and an unselected
hover receives the Medusa card-rest shadow treatment. Invalid combinations are
disabled by the product state before an interaction reaches the API.

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
