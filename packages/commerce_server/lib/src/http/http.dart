/// Reusable HTTP infrastructure: query parsing and state access.
///
/// There is no error shape here. Every refusal is a `Rejection` from
/// dust_server, which carries its own status and encodes to one JSON shape.
library;

export 'paging.dart';
export 'state.dart';
