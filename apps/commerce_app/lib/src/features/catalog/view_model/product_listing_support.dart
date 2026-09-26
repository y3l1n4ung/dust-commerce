part of 'product_listing_view_model.dart';

extension on ProductListingViewModel {
  int _begin(_ListingMeta meta) {
    final revision = ++_revision;
    _setState(meta.toState(status: ProductListingStatus.loading));
    return revision;
  }

  bool _active(int revision) => revision == _revision;

  void _missing(_ListingMeta meta) =>
      _setState(meta.toState(status: ProductListingStatus.missing));

  void _fail(_ListingMeta meta, int revision) {
    if (!_active(revision)) return;
    _setState(meta.toState(status: ProductListingStatus.failed));
  }
}

/// Stable key used to suppress stale listing state between routes.
String listingRequestKey(
  String kind,
  String handle,
  int page,
  String sortBy, [
  List<String> optionValueIds = const [],
  String currencyCode = 'usd',
  String searchQuery = '',
]) =>
    '$kind:$handle:${page < 1 ? 1 : page}:${normalizedProductSort(sortBy)}:'
    '${normalizedOptionValueIds(optionValueIds).join(',')}:$currencyCode:'
    '${normalizedSearchQuery(searchQuery)}';

/// Keeps Store search predictable and bounded before it reaches the API.
String normalizedSearchQuery(String value) {
  final query = value.trim();
  return query.length <= 120 ? query : query.substring(0, 120);
}

/// Removes empty and duplicate option values while preserving URL order.
List<String> normalizedOptionValueIds(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final raw in values) {
    final value = raw.trim();
    if (value.isNotEmpty && seen.add(value)) result.add(value);
  }
  return List.unmodifiable(result);
}

Future<List<ProductOptionFilterView>> _optionalOptionFilters(
  CommerceApi api,
  int limit,
) async {
  try {
    final result = await api.productOptions(limit: limit);
    return result.productOptions;
  } on Object {
    // Medusa treats refinement discovery as optional: products still render.
    return const [];
  }
}

Future<(ProductPageView, _ListingMeta)> _withOptionFilters(
  Future<ProductPageView> products,
  Future<List<ProductOptionFilterView>> filters,
  _ListingMeta meta,
) async {
  final values = await Future.wait<Object>([products, filters]);
  return (
    values.first as ProductPageView,
    meta.copyWith(
      optionFilters: values.last as List<ProductOptionFilterView>,
    ),
  );
}

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
    this.optionFilters = const [],
    this.selectedOptionValueIds = const [],
    this.searchQuery = '',
    this.collection = const None(),
    this.category = const None(),
    this.currencyCode = 'usd',
  });

  final Option<String> category;
  final List<ProductCategory> children;
  final Option<String> collection;
  final String currencyCode;
  final String description;
  final List<ProductOptionFilterView> optionFilters;
  final int page;
  final List<ProductCategory> parents;
  final String requestKey;
  final String searchQuery;
  final List<String> selectedOptionValueIds;
  final String sortBy;
  final String title;

  _ListingMeta copyWith({
    String? title,
    String? description,
    List<ProductCategory>? parents,
    List<ProductCategory>? children,
    List<ProductOptionFilterView>? optionFilters,
  }) =>
      _ListingMeta(
        requestKey: requestKey,
        title: title ?? this.title,
        description: description ?? this.description,
        page: page,
        sortBy: sortBy,
        parents: parents ?? this.parents,
        children: children ?? this.children,
        optionFilters: optionFilters ?? this.optionFilters,
        selectedOptionValueIds: selectedOptionValueIds,
        searchQuery: searchQuery,
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
        optionFilters: optionFilters,
        selectedOptionValueIds: selectedOptionValueIds,
        searchQuery: searchQuery,
        products: products,
        sortBy: sortBy,
        currentPage: page,
        totalPages: totalPages,
        currencyCode: currencyCode,
      );
}
