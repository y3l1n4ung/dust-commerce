part of 'product_listing_view_model.dart';

/// Stable key used to suppress stale listing state between routes.
String listingRequestKey(String kind, String handle, int page, String sortBy) =>
    '$kind:$handle:${page < 1 ? 1 : page}:${normalizedProductSort(sortBy)}';

/// Restricts public sort query values to the source-supported set.
String normalizedProductSort(String value) =>
    const {'created_at', 'price_asc', 'price_desc'}.contains(value)
        ? value
        : 'created_at';

String? _nullable(Option<String> value) => switch (value) {
      Some(:final value) => value,
      None() => null,
    };

List<Product> _sorted(
  List<Product> products,
  String sortBy,
  String currencyCode,
) {
  final sorted = products.toList(growable: false);
  if (sortBy == 'created_at') return sorted;
  sorted.sort((left, right) {
    final leftPrice = left.cheapestIn(currencyCode)?.amount;
    final rightPrice = right.cheapestIn(currencyCode)?.amount;
    if (leftPrice == null) return rightPrice == null ? 0 : 1;
    if (rightPrice == null) return -1;
    return sortBy == 'price_desc'
        ? rightPrice.compareTo(leftPrice)
        : leftPrice.compareTo(rightPrice);
  });
  return sorted;
}

List<ProductCategory> _parentsOf(
  ProductCategory category,
  List<ProductCategory> categories,
) {
  final byId = {for (final item in categories) item.id: item};
  final seen = <String>{category.id};
  final parents = <ProductCategory>[];
  var parentId = category.parentId;
  while (parentId != null && seen.add(parentId)) {
    final parent = byId[parentId];
    if (parent == null) break;
    parents.add(parent);
    parentId = parent.parentId;
  }
  return parents.reversed.toList(growable: false);
}

final class _ListingMeta {
  const _ListingMeta({
    required this.requestKey,
    required this.title,
    required this.page,
    required this.sortBy,
    this.description = '',
    this.parents = const [],
    this.children = const [],
    this.collection = const None(),
    this.category = const None(),
    this.currencyCode = 'usd',
  });

  final Option<String> category;
  final List<ProductCategory> children;
  final Option<String> collection;
  final String currencyCode;
  final String description;
  final int page;
  final List<ProductCategory> parents;
  final String requestKey;
  final String sortBy;
  final String title;

  _ListingMeta copyWith({
    String? title,
    String? description,
    List<ProductCategory>? parents,
    List<ProductCategory>? children,
  }) =>
      _ListingMeta(
        requestKey: requestKey,
        title: title ?? this.title,
        description: description ?? this.description,
        page: page,
        sortBy: sortBy,
        parents: parents ?? this.parents,
        children: children ?? this.children,
        collection: collection,
        category: category,
        currencyCode: currencyCode,
      );

  ProductListingState toState({
    required ProductListingStatus status,
    List<Product> products = const [],
    int totalPages = 0,
  }) =>
      ProductListingState(
        status: status,
        requestKey: requestKey,
        title: title,
        description: description,
        parents: parents,
        children: children,
        products: products,
        sortBy: sortBy,
        currentPage: page,
        totalPages: totalPages,
        currencyCode: currencyCode,
      );
}
