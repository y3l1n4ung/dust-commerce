part of 'product_listing_view_model.dart';

/// Stable key used to suppress stale listing state between routes.
String listingRequestKey(
  String kind,
  String handle,
  int page,
  String sortBy, [
  List<String> optionValueIds = const [],
  List<String> categoryHandles = const [],
  String currencyCode = 'usd',
  String searchQuery = '',
]) =>
    '$kind:$handle:${page < 1 ? 1 : page}:${normalizedProductSort(sortBy)}:'
    '${normalizedOptionValueIds(optionValueIds).join(',')}:'
    '${normalizedCategoryHandles(categoryHandles).join(',')}:$currencyCode:'
    '${normalizedSearchQuery(searchQuery)}';

/// Keeps Store search predictable and bounded before it reaches the API.
String normalizedSearchQuery(String value) {
  final query = value.trim();
  return query.length <= 120 ? query : query.substring(0, 120);
}

/// Removes empty and duplicate option values while preserving URL order.
List<String> normalizedOptionValueIds(Iterable<String> values) =>
    _normalizedTokens(values);

/// Removes empty and duplicate category handles while preserving URL order.
List<String> normalizedCategoryHandles(Iterable<String> values) =>
    _normalizedTokens(values);

/// Restricts public sort query values to the source-supported set.
String normalizedProductSort(String value) =>
    const {'created_at', 'price_asc', 'price_desc'}.contains(value)
        ? value
        : 'created_at';

String? _nullable(Option<String> value) => switch (value) {
      Some(:final value) => value,
      None() => null,
    };

List<String> _categoryHandles(_ListingMeta meta) {
  if (meta.selectedCategoryHandles.isNotEmpty) {
    return meta.selectedCategoryHandles;
  }
  return switch (meta.category) {
    Some(:final value) => [value],
    None() => const [],
  };
}

List<String> _normalizedTokens(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final raw in values) {
    final value = raw.trim();
    if (value.isNotEmpty && seen.add(value)) result.add(value);
  }
  return List.unmodifiable(result);
}
