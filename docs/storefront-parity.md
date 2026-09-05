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
| `layout/templates/nav` | shared storefront shell | queued in #19 |
| `home/components/hero` | home hero | queued in #19 |
| `featured-products/product-rail` | collection rail | blocked by #18 |
| `products/components/product-preview` | product card | queued in #19 |
| `store/templates` | paged catalogue | queued in #19 |
| `products/templates` | product detail route | queued in #22 |
| `products/components/product-actions` | variant state and add to cart | queued in #22 |
| `layout/components/cart-dropdown` | cart preview | queued in #21 |
| `cart/templates` | persistent cart route | queued in #21 |
| `account/templates` | account shell and session | queued in #26 |
| `checkout/templates` | checkout and payment | queued in #28 |
| `order/templates` | confirmation and order details | queued in #20 and #28 |
| categories and collections routes | product organisation | queued in #18 and #24 |

## Parity rule

A row becomes complete only when its primary interactions use the real API,
its loading, empty, failure and success states are covered, and the generated
Dust output, analyzer and tests pass. A static look-alike does not count.
