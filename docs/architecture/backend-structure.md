# Backend Module Structure

The rule every backend module follows, so a file's location predicts what is
inside it. This records where code goes and why.

Dart has no `mod.rs`. A folder that needs exports carries a barrel file named
after the folder — `handler/handler.dart` — and that file exports only, holding
no logic of its own.

Do not scaffold a folder before an issue needs code in it.

## Top-level tree

```text
packages/commerce_server/
├── lib/
│   ├── commerce_server.dart   # public entry
│   └── src/
│       ├── app/        # application assembly
│       ├── boot/       # process startup
│       ├── features/   # product behaviour
│       ├── http/       # reusable HTTP infrastructure
│       └── infra/      # external system adapters
└── test/               # feature-scoped tests
```

## Ownership

### `app/`

Application assembly: shared app state, dependency wiring, top-level router
composition, layer attachment, health routes, cross-feature route mounting.

Not here: feature use cases, SQL, HTTP request and response contracts.

### `boot/`

Process startup only: environment parsing, config classes, boot-time
validation, listener and server startup, shutdown wiring.

Not here: route handlers, product logic, SQL, request DTOs.

### `features/`

Product behaviour: DTOs, handlers, services, repositories, validation, domain
models, and the feature's routes.

### `http/`

Reusable HTTP infrastructure: the stable JSON error shape and its conversions,
JSON helpers, request IDs and tracing, shared query parsing.

Not here: product rules, feature-specific DTOs.

### `infra/`

Adapters for systems we do not own: the database pool and migrations, token
verification, object storage, external API clients.

Keep adapters generic. A product decision belongs in `features/`, even when it
is about an external system.

## Feature tree

```text
features/<feature>/
├── <feature>.dart   # feature exports and internal wiring
├── error.dart       # feature error mapping, when it needs its own
├── model.dart       # domain types and row types, not HTTP DTOs
├── router.dart      # route definitions and handler mounting
├── validation.dart  # structural and domain validation of inputs
├── dto/
│   ├── dto.dart
│   ├── request.dart
│   └── response.dart
├── handler/         # thin HTTP adapters, one file per operation
│   ├── handler.dart
│   ├── create.dart
│   ├── read.dart
│   ├── list.dart
│   ├── update.dart
│   └── delete.dart
├── repository/      # SQL only, one file per operation
│   └── ...
└── service/         # use cases and transaction orchestration
    └── ...
```

The dependency direction is `router → handler → service → repository`.

## Operation names

Inside `handler/`, `service/` and `repository/` there are **five permitted file
names and no others**:

```text
create.dart   read.dart   update.dart   delete.dart   list.dart
```

plus the barrel named after the folder. A name outside that set is not allowed,
however descriptive it seems — `place.dart`, `add_line.dart` and `load.dart` all
existed here once and all of them made a reader guess which layer and which
operation they belonged to. `read` rather than `get`, consistently.

Only the operations a feature actually serves get a file. A feature with no
delete route has no `delete.dart`; an empty file implying a route we do not
serve is worse than no file.

When an operation outgrows 180 lines it becomes a **folder of the same name**,
never a differently-named sibling:

```text
repository/
├── repository.dart
├── create/
│   ├── create.dart   # exports
│   ├── insert.dart
│   └── validate.dart
└── read.dart
```

## Row models

Dust requires database row classes to live in libraries separate from the
`@SqlxDatabase` root. They live in the feature's `model.dart`, beside the
functions that turn them into domain types — `repository/` may hold only
operation files, and a row class is not an operation.

## One DAO per operation

Dust generates one DAO per annotated class, and a class lives in one file. An
operation-shaped file therefore means an operation-shaped DAO:
`CatalogListRepository`, `CatalogReadRepository`, `CartUpdateRepository`. That
is also the smallest thing a caller has to depend on — a handler that only
reads never sees the writes.

## Tests

Tests are feature-scoped and mirror the operation names.

```text
test/
├── <feature>_test.dart   # entrypoint declaring the child parts
└── <feature>/
    ├── create.dart
    ├── get.dart
    ├── list.dart
    └── support.dart      # shared helpers for this feature's tests
```

A feature with one test file keeps that file at the top level. One file is
already one suite, so a directory around it moves a line count without dividing
a responsibility.
