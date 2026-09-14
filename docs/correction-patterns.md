# Correction pattern ledger

This ledger records mistakes that changed how the project should be built. It is
evidence for future rules, not a second rulebook. Enforced rules remain in
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Promotion process

1. Record the concrete symptom and correction in the slice where it happened.
2. Put user-directed corrections below **User correction patterns** and
   agent-detected corrections below **Self-correction patterns**.
3. Update the existing row instead of adding a differently worded duplicate.
4. Mark a recurrence only when the same failure appears in another slice.
5. Promote a candidate when it prevents a real defect and is cheap to follow.
6. Prefer an automated check; document-only rules need a clear review signal.
7. Move promoted wording to `CONTRIBUTING.md` and keep the evidence here.

Status meanings: **observed** happened once, **repeated** happened more than
once, and **promoted** already has an enforced project rule.

A candidate is not a rule. Do not treat personal preference, a one-off compile
error, or an unverified suspicion as policy. The evidence must identify the
affected slice and the authoritative check that exposed or verified it.

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
| repeated | A Dust command was run from a package directory while its `--root` was repository-relative, so workspace discovery failed. | Run repository-relative Dust commands from the repository root. | Add one repository-root verification entrypoint that validates its working directory before Dust runs. |
| repeated | Package-prefixed paths were passed to `dart format` from inside that package; it found no files but the surrounding command still reached a successful analyzer exit. | Resolve paths against the command working directory and treat “formatted no files” as a failed preflight. | The verification entrypoint must resolve every target from the repository root and reject an empty target set. |
| observed | `dart analyze --no-fatal-infos` was copied from another analyzer workflow, but this SDK does not support that option. | Use the repository's plain `dart analyze` or `flutter analyze --no-pub` commands without guessed flags. | Keep package-specific analyzer commands in one checked script. |
| observed | A strict `JsonExtractable` unknown-key test expected `400`, but Dust Server classifies a syntactically valid body it cannot construct as `422`. | Pin tests to the extractor's documented rejection classes: media type `415`, syntax `400`, construction or validation `422`. | Add one shared extractor-status contract test and reuse its expectations. |
| observed | Adding the refund-reason table made the exact migration inventory test fail at 60 versus its old 59 expectation. | Update the migration inventory contract in the same schema slice as every added or removed migration. | Derive the expected inventory from a reviewed manifest, then prove run, revert and re-run. |
| repeated | Tests were started with the wrong runner or from the workspace root, so Flutter lacked `dart:ui` or Dart found no root `test/` directory. | Run each suite from its owning package; use `flutter test --no-pub` for Flutter and `dart test` for pure Dart. | A package-aware root verifier should select both runner and working directory from `pubspec.yaml`. |
| observed | Preflight assumed a root `dust.yaml`, but the relevant configuration belonged to an application package. | Locate Dust configuration with `rg --files -g dust.yaml` before reading or invoking it. | Preflight prints the resolved configuration path. |
| observed | `sqlx migrate run` was pointed at a copied legacy QA database whose schema history belonged to Dust's embedded runner, so SQLx tried to replay existing tables. | Production-style QA starts from a fresh SQLx database unless `_sqlx_migrations` is already present and matches the binary. | Preflight the migration-history table and fail before applying anything to an incompatible database. |
| observed | A QA script guessed a shipping option's field as `id` and selected a conditional free rate that the cart did not qualify for. | Read generated contracts or observed responses instead of guessing keys, then select data whose published rules are satisfied. | Assert required response keys and eligibility with `jq -e` before sending the next mutation. |
| observed | A long-running test handle expired during context compaction. | Missing process state is unknown, never a pass; rerun the exact authoritative check. | Final evidence must include a current exit code and test count. |
| observed | A `State` lifecycle helper moved into an extension and called protected `setState`, producing an analyzer warning. | Keep protected `State` calls in the `State` subclass; extracted parts may delegate back to an instance method. | Treat analyzer warnings as failures before commit. |
| repeated | A repository-wide gate failed on known legacy files even though the changed slice was compliant. | Report baseline debt separately and prove every touched file passes the same limit. | CI should eventually compare new violations against an explicit baseline. |
| observed | A fixture sent multiple SQL statements through one Dust raw query, which rejects trailing statements. | Execute exactly one SQL statement per raw query call. | Fixture helpers should accept one statement and tests should fail on every returned database error. |
| observed | SQLx converter declarations lived in a Dart `part`; normal Dust generation lost their input types and emitted `read<Object?>`. | Keep SQLx converter declarations in the owning library until the generator resolves declarations across parts. | `dust check` and `dust check --db` must both inspect the generated read types. |
| observed | A diagnostic command followed a failed verifier in the same shell chain and its zero exit masked the failure. | Run the authoritative verifier as the terminal command or preserve and assert its exit code before diagnostics. | Verification scripts use strict mode and never append non-authoritative commands after the gate. |
| observed | A zsh QA script assigned to the read-only special parameter `status` and stopped before assertions. | Use task-scoped shell variable names that cannot collide with shell state. | Shellcheck plus a project prefix for temporary script variables. |
| observed | A live Admin fixture ignored a failed insert whose foreign-key prerequisite was absent, leaving the expected customer order missing. | Seed required parents and assert every fixture write before browser QA. | Shared seed helpers return failures; QA scripts stop on the first rejected write. |
| observed | The customer detail breakpoint was based on inner content width, while Medusa's `xl` decision is based on viewport width, so a 1280 viewport collapsed incorrectly. | Translate source breakpoints into the local shell's actual content threshold and verify both sides of the breakpoint. | Capture the same route at the target desktop viewport and one compact viewport before closing visual QA. |

## Entry template

Add a row only after a concrete correction:

```text
Status: observed | repeated | promoted
Source: user correction | self-correction
Symptom: what failed or created risk
Correction: what changed the decision
Candidate: the smallest durable rule
Enforcement: the cheapest reliable check
Evidence: affected slice plus branch, commit, test, or review reference
```
