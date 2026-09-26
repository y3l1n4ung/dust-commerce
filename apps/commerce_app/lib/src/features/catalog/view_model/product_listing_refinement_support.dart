part of 'product_listing_view_model.dart';

List<ProductCategoryFilter> _categoryFiltersOf(List<Product> products) {
  final names = <String, String>{};
  final counts = <String, int>{};
  for (final product in products) {
    final seen = <String>{};
    for (final category in product.categories) {
      final handle = category.handle.trim();
      if (handle.isEmpty || !seen.add(handle)) continue;
      names[handle] = category.name.trim().isEmpty ? handle : category.name;
      counts[handle] = (counts[handle] ?? 0) + 1;
    }
  }
  final filters = [
    for (final entry in counts.entries)
      ProductCategoryFilter(
        handle: entry.key,
        name: names[entry.key]!,
        count: entry.value,
      ),
  ]..sort((left, right) {
      final byCount = right.count.compareTo(left.count);
      return byCount == 0 ? left.name.compareTo(right.name) : byCount;
    });
  return List.unmodifiable(filters.take(20));
}

List<ProductLabelFilter> _labelFiltersOf(List<Product> products) {
  final counts = <String, int>{};
  for (final product in products) {
    final seen = <String>{};
    for (final tag in product.tags) {
      final value = tag.value.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  final filters = [
    for (final entry in counts.entries)
      ProductLabelFilter(value: entry.key, count: entry.value),
  ]..sort((left, right) {
      final byCount = right.count.compareTo(left.count);
      return byCount == 0 ? left.value.compareTo(right.value) : byCount;
    });
  return List.unmodifiable(filters.take(20));
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

Future<List<ProductCategoryFilter>> _optionalCategoryFilters(
  CommerceApi api,
  int limit,
  _ListingMeta meta,
) async {
  try {
    final result = await api.products(
      currency: meta.currencyCode,
      query: meta.searchQuery.isEmpty ? null : meta.searchQuery,
      collection: _nullable(meta.collection),
      categoryHandles: const [],
      labels: meta.selectedLabelValues,
      optionValueIds: meta.selectedOptionValueIds,
      limit: limit,
    );
    return _categoryFiltersOf(result.products);
  } on Object {
    // Medusa keeps product results usable when facet discovery is unavailable.
    return const [];
  }
}

Future<List<ProductLabelFilter>> _optionalLabelFilters(
  CommerceApi api,
  int limit,
  _ListingMeta meta,
) async {
  try {
    final result = await api.products(
      currency: meta.currencyCode,
      query: meta.searchQuery.isEmpty ? null : meta.searchQuery,
      collection: _nullable(meta.collection),
      categoryHandles: meta.selectedCategoryHandles,
      labels: const [],
      optionValueIds: meta.selectedOptionValueIds,
      limit: limit,
    );
    return _labelFiltersOf(result.products);
  } on Object {
    return const [];
  }
}

Future<(ProductPageView, _ListingMeta)> _withRefinementFilters(
  Future<ProductPageView> products,
  Future<List<ProductOptionFilterView>>? optionFilters,
  Future<List<ProductCategoryFilter>>? categoryFilters,
  Future<List<ProductLabelFilter>>? labelFilters,
  _ListingMeta meta,
) async {
  final values = await Future.wait<Object>([
    products,
    optionFilters ?? Future.value(meta.optionFilters),
    categoryFilters ?? Future.value(meta.categoryFilters),
    labelFilters ?? Future.value(meta.labelFilters),
  ]);
  return (
    values.first as ProductPageView,
    meta.copyWith(
      optionFilters: values[1] as List<ProductOptionFilterView>,
      categoryFilters: values[2] as List<ProductCategoryFilter>,
      labelFilters: values[3] as List<ProductLabelFilter>,
    ),
  );
}
