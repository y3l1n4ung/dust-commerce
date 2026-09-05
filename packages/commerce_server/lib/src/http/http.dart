/// Reusable HTTP infrastructure: query parsing.
///
/// There is no error shape here. Every refusal is a `Rejection` from
/// dust_server, which carries its own status and encodes to one JSON shape —
/// including a 422 with per-field errors, which is what a validation failure
/// needs and what this package used to hand-build.
library;

export 'paging.dart';
