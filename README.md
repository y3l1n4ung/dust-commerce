# dust-commerce

A headless commerce backend and storefront, written in Dart end to end, built to
show what [Dust](https://github.com/y3l1n4ung/dust) generates in a real
application rather than in a snippet.

## What this is a clone of

The domain model follows **[Medusa](https://github.com/medusajs/medusa)** — the
MIT-licensed headless commerce platform written in TypeScript. Medusa was chosen
because its model is the one most commerce projects converge on, it is widely
used, and its licence puts no constraints on studying it.

**This is a reimplementation, not a port.** No Medusa code, schema dump, asset,
or piece of branding was copied. What is borrowed is the shape of the domain —
that a product owns variants, that a variant rather than a product carries price
and stock, that a cart holds line items which snapshot their price at the time
of adding, that an order is a frozen cart. Those are ideas, and ideas are what
you are allowed to learn from.

This project is not affiliated with, endorsed by, or derived from Medusa.

### What is modelled

| Concept | Follows Medusa in | Deliberately simplified |
| :--- | :--- | :--- |
| `Product` / `ProductVariant` | variants carry price and stock, not the product | no attribute/option matrix |
| `Money` | integer minor units plus currency, never a float | single currency per region |
| `Cart` / `LineItem` | line items snapshot unit price when added | no promotions engine |
| `Order` | an immutable snapshot of a cart at checkout | no fulfilment or returns |
| `Region` | currency and tax rate scope | no multi-warehouse |
| `Customer` / `Address` | separate addressable entities | no saved payment methods |

Prices are integer minor units throughout. Storing money in a floating point
type is the most common bug in commerce code and it is not reproduced here.

## Why it exists

Dust generates Dart from annotations. This repository is the case where that
matters most: **one set of model definitions, generated in both directions.**
The server decodes exactly what the client's generated HTTP client encodes,
because both sides are generated from the same `commerce_shared` classes. Change
a field once and both ends move together, or fail to compile together.

## What is generated, and what is not

Being precise about this is part of the point of the repository.

| Layer | Dust generates | Written by hand |
| :--- | :--- | :--- |
| `commerce_shared` | data classes, JSON, validation | the model definitions |
| `commerce_server` | row mapping, DAOs, static SQL checking | routing, handlers, extractors |
| `commerce_app` | routing, view models, i18n, the HTTP client | widgets |

There is no server code generator in Dust today. Handlers are written against
`dust_server`'s API directly, and that is not a workaround — the runtime is
designed to be written against.

## Layout

```
packages/commerce_shared   models shared across the wire
packages/commerce_server   dust_server API on SQLite
apps/commerce_app          Flutter storefront
```

[docs/architecture](docs/architecture/) traces one request from widget to row
and records the decisions that would be expensive to reverse.

## Running it

Requires the Dust CLI at 0.1.4 or newer:

```bash
dust --version
```

```bash
flutter pub get
dust build --root packages/commerce_shared
dust build --root packages/commerce_server && dust db build --root packages/commerce_server
dust build --root apps/commerce_app
```

Then the same checks CI runs:

```bash
./scripts/format.sh --check && ./scripts/check_file_size.sh
```

## Licence

MIT. See [LICENSE](LICENSE).
