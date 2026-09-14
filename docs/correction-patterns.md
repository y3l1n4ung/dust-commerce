# Correction pattern ledger

This ledger records mistakes that changed how the project should be built. It is
evidence for future rules, not a second rulebook. Enforced rules remain in
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Promotion process

1. Record the concrete symptom and correction without generalizing it.
2. Mark a recurrence only when the same failure appears in another slice.
3. Promote a candidate when it prevents a real defect and is cheap to follow.
4. Prefer an automated check; document-only rules need a clear review signal.
5. Move promoted wording to `CONTRIBUTING.md` and keep the evidence here.

Status meanings: **observed** happened once, **repeated** happened more than
once, and **promoted** already has an enforced project rule.

## User correction patterns

| Status | Symptom | Durable candidate | Enforcement idea |
| :--- | :--- | :--- | :--- |
| promoted | A private method returned `Widget`, hiding composition and rebuild ownership. | Every UI subtree is a dedicated widget class; only framework `build` methods return widgets. | Scan handwritten Dart for private `Widget` or `List<Widget>` methods. |
| promoted | A service boundary could return `Result<Result<T, DomainFailure>, SqlxError>`. | One feature failure type crosses each boundary; map infrastructure failures before returning. | Search for nested `Result` signatures and test each error mapping. |
| repeated | Response types inherited database or domain models and could disclose new internal fields. | Store and Admin responses are standalone explicit allowlists. | Contract review checks inheritance and round-trip tests pin serialized keys. |
| repeated | SQL rows were mapped to an intermediate model and then converted again. | Use direct SQLx `FromRow` response projections when the query already selects the public allowlist. | Query tests compile and decode the exact response target. |
| repeated | Nullable UI state blurred “not loaded”, “missing”, and “failed”. | Use `Option` for state absence; keep nullable fields only at wire or SQL boundaries where null is data. | State review plus equality tests for idle, empty, and failed states. |
| repeated | Authorization was threaded through API methods or parsed in handlers. | Dio owns bearer attachment; protected routers use a route guard and handlers require the authenticated extractor. | Route tests cover missing, invalid, foreign, and owned credentials; API signatures contain no token. |
| repeated | Timestamps came from application clocks or were represented as strings in Dart. | SQLite owns UTC ISO-text timestamps; Dart contracts use `DateTime`. | Schema checks reject application timestamp parameters; serialization tests assert UTC instants. |
| repeated | Migration follow-ups patched a table with appended `ALTER TABLE` files. | For unreleased schema work, write a one-shot final table migration, one table per reversible migration. | Migration inventory check plus clean `sqlx migrate run` and `sqlx migrate revert` verification. |
| repeated | Password handling risked generic hashes or plaintext-shaped storage. | Hash passwords with Argon2id and store only self-describing PHC values. | Authentication tests cover fresh salt, verify, wrong secret, and no plaintext persistence. |
| promoted | Handwritten files grew by accumulating unrelated helpers. | Keep handwritten files within 180 code lines and split by responsibility. | `scripts/check_file_size.sh`; fail only newly introduced violations while legacy debt is reduced. |
| promoted | Generated `.g.dart` output was formatted or edited by hand and became stale. | Commit generator output exactly as emitted. | `dust check`, `dust check --db`, and handwritten-only formatting. |
| repeated | Large feature branches mixed contracts, backend, UI, QA, and documentation. | Use short stacked branches and commits, one responsibility per slice. | Review each commit independently and keep its verification evidence scoped. |
| repeated | UI polish started before the capability worked, or screenshots substituted for source understanding. | Implement and test the vertical feature first; compare pinned source code before rendered visual QA. | Parity docs name source commit, functional evidence, and remaining rendered QA separately. |
| observed | Widget tests were added before the requested testing phase. | Do not add widget tests until that phase is explicitly opened; use unit, contract, and browser QA meanwhile. | Review test type in each slice. |
| repeated | Product identity drifted to an internal project name, attribution, or common development port. | Customer brand is Morrow, attribution is only `Powered by dust`, and Store/Admin/API use 13001/13002/3878. | Browser smoke assertions and configuration constants. |

## Self-correction patterns

| Status | Symptom | Durable candidate | Enforcement idea |
| :--- | :--- | :--- | :--- |
| observed | A weak-context patch placed an import at the end of a Dart file. | Patch imports and structural edits with anchored context, then inspect the changed file before formatting. | Run analyzer, formatter, `git diff --check`, and inspect head/tail after structural patches. |
| repeated | A Dust command was run from a package directory while its `--root` was repository-relative, so workspace discovery failed. | Run repository-relative Dust commands from the repository root. | Add a wrapper or preflight that prints and validates the working directory. |
| repeated | Package-prefixed paths were passed to `dart format` from inside that package; it found no files but the surrounding command still reached a successful analyzer exit. | Resolve paths against the command working directory and treat “formatted no files” as a failed preflight. | Run package tools from the package root with package-relative paths and assert every target exists first. |
| observed | `dart analyze --no-fatal-infos` was copied from another analyzer workflow, but this SDK does not support that option. | Use the repository's plain `dart analyze` or `flutter analyze --no-pub` commands without guessed flags. | Keep package-specific analyzer commands in one checked script. |
| observed | A strict `JsonExtractable` unknown-key test expected `400`, but Dust Server classifies a syntactically valid body it cannot construct as `422`. | Pin tests to the extractor's documented rejection classes: media type `415`, syntax `400`, construction or validation `422`. | Add one shared extractor-status contract test and reuse its expectations. |
| observed | Adding the refund-reason table made the exact migration inventory test fail at 60 versus its old 59 expectation. | Update the migration inventory contract in the same schema slice as every added or removed migration. | Derive the expected inventory from a reviewed manifest, then prove run, revert and re-run. |
| observed | Flutter tests were started with `dart test`, so `dart:ui` was unavailable and the compiler failed before testing the slice. | Run Flutter package tests with `flutter test --no-pub`; reserve `dart test` for pure Dart packages. | Package-aware test wrappers should select the runner from `pubspec.yaml`. |
| observed | Preflight assumed a root `dust.yaml`, but the relevant configuration belonged to an application package. | Locate Dust configuration with `rg --files -g dust.yaml` before reading or invoking it. | Preflight prints the resolved configuration path. |
| observed | `sqlx migrate run` was pointed at a copied legacy QA database whose schema history belonged to Dust's embedded runner, so SQLx tried to replay existing tables. | Production-style QA starts from a fresh SQLx database unless `_sqlx_migrations` is already present and matches the binary. | Preflight the migration-history table and fail before applying anything to an incompatible database. |
| observed | A QA script guessed a shipping option's field as `id` and selected a conditional free rate that the cart did not qualify for. | Read generated contracts or observed responses instead of guessing keys, then select data whose published rules are satisfied. | Assert required response keys and eligibility with `jq -e` before sending the next mutation. |
| observed | A long-running test handle expired during context compaction. | Missing process state is unknown, never a pass; rerun the exact authoritative check. | Final evidence must include a current exit code and test count. |
| observed | A `State` lifecycle helper moved into an extension and called protected `setState`, producing an analyzer warning. | Keep protected `State` calls in the `State` subclass; extracted parts may delegate back to an instance method. | Treat analyzer warnings as failures before commit. |
| repeated | A repository-wide gate failed on known legacy files even though the changed slice was compliant. | Report baseline debt separately and prove every touched file passes the same limit. | CI should eventually compare new violations against an explicit baseline. |

## Entry template

Add a row only after a concrete correction:

```text
Status: observed | repeated | promoted
Symptom: what failed or created risk
Correction: what changed the decision
Candidate: the smallest durable rule
Enforcement: the cheapest reliable check
Evidence: branch, commit, test, or review reference
```
