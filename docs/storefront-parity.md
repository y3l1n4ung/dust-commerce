# Medusa DTC storefront parity

The implementation target is the customer-facing storefront in
[medusajs/dtc-starter](https://github.com/medusajs/dtc-starter), pinned at
`19e8a6fbefea5a385e9502409908bfbebbecf526`. React and Next.js constructs are
translated into native Flutter and Dust patterns; the application talks only
to the dust-commerce API.

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
| `products/templates` | product detail route | partial in #22; gallery and tabs remain |
| `products/components/product-actions` | variant state and add to cart | partial in #22; unavailable combinations remain |
| `layout/components/cart-dropdown` | cart preview | queued in #21 |
| `cart/templates` | cart route | partial in #21; persistence and mutations remain |
| `account/templates` | account shell and session | queued in #26 |
| `checkout/templates` | checkout and payment | queued in #28 |
| `order/templates` | confirmation and order details | queued in #20 and #28 |
| categories and collections routes | product organisation | queued in #18 and #24 |

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
