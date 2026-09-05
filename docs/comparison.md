# Compared with Medusa

What this project takes from [Medusa](https://github.com/medusajs/medusa), what
it does differently, and — first, because it is the part a comparison usually
hides — how much of Medusa it does not attempt.

Checked against Medusa's documentation in September 2026. Where a claim about
Medusa is made here, it comes from their docs rather than recollection.

## Scale, before anything else

Medusa ships **16 commerce modules and 7 infrastructure modules**:

> Cart · Payment · Customer · Pricing · Promotion · Product · Order · Inventory
> · Fulfillment · Stock Location · Region · Sales Channel · Tax · Currency · API
> Keys · User · Auth
>
> Analytics · Caching · Event · File · Locking · Notification · Workflow Engine

This project implements one storefront path across parts of six of them, and
has an admin surface of zero. It is a **showcase of Dust code generation built
on a Medusa-shaped domain**, not an alternative to Medusa, and the gap is three
orders of magnitude of product rather than a few missing endpoints.

| | Medusa | dust-commerce |
| :--- | :--- | :--- |
| Commerce modules | 16 | parts of 6 |
| Infrastructure modules | 7 | 0 |
| Admin API | yes | none |
| Storefront endpoints | dozens | 8 |
| Workflow engine, plugins, dashboard | yes | none |

## Where the model genuinely agrees

These are the decisions worth copying, and each one is enforced by a test here.

### A line item denormalises what it was bought at

Medusa's `LineItem` carries `unit_price`, `product_title`, `variant_title`,
`variant_sku` and `variant_option_values` as its own columns. Their docs give
the reason plainly: it *"allows line items to retain product/variant
information independently of whether the source data changes."*

Same here, same reason. `LineItem.fromVariant` takes the price at the moment of
adding and nothing reads it again. The test does not trust the code: it adds a
line, updates `variant_prices` in the database, reloads the cart over HTTP, and
asserts the line and the subtotal did not move.

### The variant is the sellable thing

Price and stock hang off `ProductVariant`, not `Product`, in both. A medium
black shirt and a large black shirt are separately counted and shipped, and a
model that prices the product cannot say that.

### Options are an axis on the product, values a choice on the variant

`ProductOption` holds the permitted values; each variant records the value it
chose. That is what lets a storefront render a size selector without inspecting
every variant to discover the sizes, and `Product.variantFor({'opt_size':
'Large'})` is the call a selector makes.

### A region fixes currency and tax

A cart belongs to a region, and that decides the currency every line must be
priced in and the rule the total is computed under — rather than being looked
up at checkout, where it could disagree with what was displayed.

## Where this project deliberately differs

### Money is an integer, and only an integer

Medusa uses a `BigNumber` property for amounts. This project uses a plain `int`
count of the currency's minor unit, divided by a hundred in exactly one place
at the edge of the UI. It is a narrower choice — it cannot express a fractional
minor unit, which some tax and multi-currency work wants — and it is deliberate:
the arithmetic is exact, and every layer that is not the renderer is incapable
of introducing a rounding error.

Tax rounds half away from zero, pinned by a test at 8.75% of 1999, where
truncation under-collects by one unit on every line of every order.

### Prices live on the variant, not in a pricing module

Medusa separates Pricing into its own module, which is what buys price lists,
customer-group pricing and quantity breaks. Here a variant simply has at most
one price per currency, enforced by the primary key `(variant_id,
currency_code)` rather than by convention. Simpler, and correspondingly less
capable.

### Stock is a column, not an Inventory module

Medusa has Inventory and Stock Location modules, so one variant can be stocked
in several places. Here `inventory_quantity` is a column on the variant, and
stock is taken by a conditional `UPDATE` inside the checkout transaction. That
handles the race — two checkouts for the last unit, only one wins, and a zero
row count is how the loser finds out — but it cannot answer *which warehouse*.

### The order is frozen harder

Every amount on an order is stored. Lines and addresses are copied, not
referenced, so editing an account's address later cannot rewrite where
something was already shipped. Medusa denormalises heavily too; this project
takes it further by storing `subtotal`, `tax` and `total` rather than deriving
them, and the assembler reads them back rather than recomputing.

## Not attempted

Payments, fulfilment and shipping options, promotions and discounts, tax
providers, inventory locations, sales channels, collections and categories,
product types and tags, search, customer accounts and authentication, API keys,
the admin API, the workflow engine, the plugin system, notifications, file
storage, and the admin dashboard.

Guest checkout works — an email and an address are enough — because there is no
auth to work around, not because guest checkout was designed.

## The honest summary

On the eight endpoints it serves, the domain modelling holds up against
Medusa's and the reasons behind it are the same reasons. On everything else,
Medusa is a commerce platform and this is a demonstration that Dust can
generate one end of a wire and decode it at the other.

If you want to sell something, use Medusa. If you want to see what a Dart
codebase looks like when the models on both sides of the network are generated
from one definition, read [the architecture notes](architecture/README.md).
