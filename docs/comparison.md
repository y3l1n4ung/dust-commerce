# Compared with Medusa

What this project takes from [Medusa](https://github.com/medusajs/medusa), what
it does differently, and — first, because it is the part a comparison usually
hides — how much of Medusa it does not attempt.

Checked head to head against Medusa source commit
`bda24b9725ac697ec5e8f706b503013e20babf12` from 2026-09-04. The comparison
uses the customer and auth models/migrations, email/password provider, and
registration flow at that commit rather than relying on recollection.

## Scale, before anything else

Medusa is a modular commerce platform. This project is a **showcase of Dust
code generation built on a Medusa-shaped domain**, not an alternative to
Medusa. It implements only the path from catalog to cart, checkout, manual
payment, and a basic customer account.

| | Medusa | dust-commerce |
| :--- | :--- | :--- |
| Schema | modular PostgreSQL schemas | 20 SQLite tables |
| Admin API | yes | none |
| Store operations | broad Store API | 18 method/path operations |
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

### Customer data and provider credentials are separate

Both schemas keep the customer profile apart from authentication. The account
path creates `customers`, `auth_identity`, and `provider_identity` records in
one transaction. The customer has Medusa's `has_account` distinction and its
active uniqueness rule on `(email, has_account)`, so one guest and one account
record may share an email without permitting two active accounts.

`provider_identity` owns the provider-scoped identifier and provider metadata;
`auth_identity.app_metadata` links the authenticated actor to the customer.
That keeps a later provider from forcing credential columns onto `customers`.

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

### Password hashing is Argon2id, not Medusa's current scrypt provider

At the pinned commit, Medusa's email/password provider imports `scrypt-kdf`.
This project deliberately uses `cryptography`'s Argon2id with 19 MiB memory,
two iterations, one lane, a fresh 16-byte secure salt, and a 32-byte result. It
stores the self-describing PHC string in provider metadata and never stores or
serializes the plaintext password.

### Sessions are small and revocable

Instead of Medusa's wider token/session machinery, this service issues a
256-bit opaque bearer token with a seven-day expiry. Only its SHA-256
fingerprint is stored, so reading the database cannot replay a live session;
sign-out deletes the fingerprint. Unknown-email and wrong-password sign-in do
the same Argon2 work and return the same response.

### PostgreSQL timestamps become explicit SQLite UTC text

Medusa's PostgreSQL migrations use `timestamptz not null default now()`.
SQLite has no native `TIMESTAMPTZ`, so every automatic timestamp here is a
stored ISO-8601 UTC `TEXT` value ending in `Z`, supplied by a database default;
mutable root tables use triggers for `updated_at`. They are not generated
columns. A PostgreSQL port should replace them with real `TIMESTAMPTZ` rather
than copying this SQLite representation.

## Not attempted

Fulfilment and returns, real payment providers or saved payment methods,
provider-driven taxes, inventory locations, sales channels, collections and
categories, product types and tags, search, password reset, email verification,
MFA, OAuth providers, API keys, the admin API, workflow engine, plugin system,
notifications, file storage, and the admin dashboard.

Shipping is one regional flat-price option, promotions are one fixed or
percentage code, payment is a manual state transition, and authentication is
email/password plus opaque sessions. Those are tested vertical slices, not the
corresponding Medusa modules in miniature.

## The honest summary

Across its 18 method/path operations, the domain modelling follows the same
core boundaries where they fit. On everything else, Medusa is a commerce
platform and this is a demonstration that Dust can generate one end of a wire,
decode it at the other, and statically validate SQL against a real schema.

If you want to sell something, use Medusa. If you want to see what a Dart
codebase looks like when the models on both sides of the network are generated
from one definition, read [the architecture notes](architecture/README.md).
