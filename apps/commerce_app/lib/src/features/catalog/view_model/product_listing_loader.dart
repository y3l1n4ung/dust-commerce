part of 'product_listing_view_model.dart';

extension _ProductListingLoader on ProductListingViewModel {
  Future<void> _loadProducts(
    _ListingMeta meta,
    int revision, {
    Future<List<ProductOptionFilterView>>? optionFilters,
    Future<List<ProductCategoryFilter>>? categoryFilters,
  }) async {
    try {
      final productRequest = args.api.products(
        currency: meta.currencyCode,
        query: meta.searchQuery.isEmpty ? null : meta.searchQuery,
        collection: _nullable(meta.collection),
        categoryHandles: _categoryHandles(meta),
        optionValueIds: meta.selectedOptionValueIds,
        limit: ProductListingViewModel._sourceFetchLimit,
      );
      final (result, resolvedMeta) = await _withRefinementFilters(
        productRequest,
        optionFilters,
        categoryFilters,
        meta,
      );
      if (!_active(revision)) return;
      final sorted = _sorted(
        result.products,
        resolvedMeta.sortBy,
        resolvedMeta.currencyCode,
      );
      final start = (resolvedMeta.page - 1) * ProductListingViewModel._limit;
      final end = (start + ProductListingViewModel._limit).clamp(
        0,
        sorted.length,
      );
      final products = start >= sorted.length
          ? const <Product>[]
          : sorted.sublist(start, end);
      _setState(resolvedMeta.toState(
        status: ProductListingStatus.ready,
        products: products,
        totalPages: (sorted.length + ProductListingViewModel._limit - 1) ~/
            ProductListingViewModel._limit,
      ));
    } on Object {
      _fail(meta, revision);
    }
  }
}
