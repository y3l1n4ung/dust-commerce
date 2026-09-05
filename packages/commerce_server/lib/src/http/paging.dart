import 'package:dust_server/server.dart';

/// How many rows a listing returns when the caller does not say.
const int defaultLimit = 20;

/// The most a caller may ask for in one page.
///
/// A cap rather than an honoured request: without one, `?limit=1000000` is a
/// denial of service anybody can send.
const int maxLimit = 100;

/// The `limit` and `offset` a request asked for, clamped to what is allowed.
///
/// A value that is not a number, or is negative, falls back to the default
/// rather than failing the request. Paging is not the point of the call, and
/// rejecting a whole listing over a malformed query string serves nobody.
({int limit, int offset}) pagingOf(Request request) {
  final query = request.requestedUri.queryParameters;
  final limit = int.tryParse(query['limit'] ?? '') ?? defaultLimit;
  final offset = int.tryParse(query['offset'] ?? '') ?? 0;

  return (
    limit: limit.clamp(1, maxLimit),
    offset: offset < 0 ? 0 : offset,
  );
}

/// The currency a request asked to be priced in, lower case.
///
/// Defaults to [fallback] rather than failing, so a storefront that has not
/// picked a region yet still renders.
String currencyOf(Request request, {String fallback = 'usd'}) {
  final asked = request.requestedUri.queryParameters['currency'];
  if (asked == null || asked.length != 3) return fallback;
  return asked.toLowerCase();
}
