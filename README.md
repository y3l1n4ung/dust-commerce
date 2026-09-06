# dust-commerce

A headless commerce backend and storefront, written in Dart end to end, built to
show what [Dust](https://github.com/y3l1n4ung/dust) generates in a real
application rather than in a snippet.

## What this is a clone of

The domain model follows **[Medusa](https://github.com/medusajs/medusa)** — the
MIT-licensed headless commerce platform written in TypeScript. Medusa was chosen
because its model is the one most commerce projects converge on, it is widely
used, and its licence puts no constraints on studying it.

**This is a source-guided reimplementation, not a runtime port.** The Flutter
storefront translates the MIT-licensed Medusa DTC Starter screen structure and
interaction flow into Dust patterns; it does not embed React, Next.js, or the
Medusa SDK. The backend remains an independent Dart and SQLite implementation.
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the pinned source and
attribution.

This project is not affiliated with, endorsed by, or derived from Medusa.

[docs/comparison.md](docs/comparison.md) sets the two side by side against a
pinned Medusa source commit. This project implements one narrow storefront path
and has no admin surface, workflow engine, or plugin platform.

### What is modelled

| Concept | Follows Medusa in | Deliberately simplified |
| :--- | :--- | :--- |
| `Product` / `ProductVariant` | variants carry price and stock, not the product | one simple option matrix |
| `Money` | integer minor units plus currency, never a float | single currency per region |
| `Cart` / `LineItem` | line items snapshot unit price when added | one shipping method and promotion per cart |
| `Order` | an immutable snapshot of a cart at checkout | no fulfilment or returns |
| `Region` | currency and tax rate scope | no multi-warehouse |
| `Customer` / `AuthIdentity` | customer data is separate from provider credentials | email/password only; no reset, MFA, or OAuth |
| `PaymentCollection` | payment state belongs to the order | manual provider only; no card data |

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

Start a local API with the deterministic development catalogue:

```bash
COMMERCE_SEED=true \
  COMMERCE_ALLOWED_ORIGINS=http://127.0.0.1:3000 \
  COMMERCE_DATABASE_PATH=.data/commerce.db \
  dart run packages/commerce_server/bin/server.dart
```

The seed is opt-in and idempotent. Production startup never creates merchant or
customer records. Bind address, port, database path, and browser origins are
configured with `COMMERCE_BIND`, `COMMERCE_PORT`, `COMMERCE_DATABASE_PATH`, and
comma-separated `COMMERCE_ALLOWED_ORIGINS`.

To reset development data safely, stop the API and point
`COMMERCE_DATABASE_PATH` at a new file. Keep the old database as a backup until
the replacement stack has started and passed `/health`.

In a second terminal, start the Flutter web storefront:

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 3000 \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Then the same checks CI runs:

```bash
./scripts/format.sh --check && ./scripts/check_file_size.sh
```

The process-level smoke starts the real server entrypoint against a temporary
database, waits for health, verifies the four-product catalogue, shuts it down
gracefully, and restarts it against the same database to prove seeding remains
idempotent:

```bash
dart test packages/commerce_server/test/server_entrypoint_test.dart
```

### Database migrations

The server uses SQLite, so UTC instants are stored as sortable ISO-8601 `TEXT`
with database defaults and update triggers. SQLite has no native PostgreSQL
`TIMESTAMPTZ`; no timestamp column is generated.

The baseline is intentionally one final table per timestamped reversible SQLx
pair. Create another pair with:

```bash
sqlx migrate add <table_name> -r --timestamp \
  --source packages/commerce_server/migrations
```

This is a migration-history reset from the former `0001`-`0005` files. Do not
point it at a database that already recorded those versions: rebuild a backed-up
pre-release database, or ship a separately designed bridge migration instead.

Use SQLx for explicit forward/reverse operation:

```bash
DATABASE_URL=sqlite://commerce.db sqlx migrate run \
  --source packages/commerce_server/migrations
DATABASE_URL=sqlite://commerce.db sqlx migrate revert \
  --source packages/commerce_server/migrations
```

Dust embeds and applies the `.up.sql` files at server startup. It does not run
down migrations automatically. The baseline contains no appended `ALTER TABLE`
steps: each table's up file is its complete initial definition.

## Licence

MIT. See [LICENSE](LICENSE).
