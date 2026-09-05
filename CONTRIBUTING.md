# Contributing

## Rules that are not negotiable

1. **Tests first.** Write the failing test, watch it fail for the right reason,
   then write the code. A test written after the code proves the code runs, not
   that it is correct.
2. **180 lines of code per file.** Generated `.g.dart` files are exempt; they
   are output, not source. When a file crosses the limit, split by
   responsibility, never by line count.
3. **A folder is not scaffolded before an issue needs code in it.** An empty
   directory implying a route we do not serve is worse than no directory.
4. **Generated output is committed.** CI runs `dust check` and `dust check --db`
   to prove the committed files match their sources.

## Splitting

A file that crosses 180 lines becomes a folder of the same name, with a barrel
file exporting the parts:

```text
repository/
├── repository.dart   # exports
├── create/
│   ├── create.dart   # exports
│   ├── insert.dart
│   └── validate.dart
└── get.dart
```

A split that leaves one file holding everything and another holding a helper has
not divided a responsibility; it has moved a line count.

## Ordering

- Sort files and folders A–Z where practical.
- Group a file by section, sort members A–Z within a section.
- Public items above private helpers, so a reader meets the contract before the
  mechanics.

## Commits

Conventional commits. The body says why, not what — the diff already says what.

## Verifying

```bash
dust build --root packages/commerce_shared
dust build --root packages/commerce_server && dust db build --root packages/commerce_server
dust build --root apps/commerce_app
```

```bash
./scripts/format.sh && ./scripts/check_file_size.sh
```

Never run `dart format` across a package. It rewrites generated files into
something the generator would not emit, and `dust check` then reports all of
them stale. `scripts/format.sh` formats handwritten Dart and skips the rest.
