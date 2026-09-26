import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/features/catalog/model/product_listing_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'product_listing_view_model.g.dart';
part 'product_listing_support.dart';

/// Dependencies for source-shaped product listing routes.
final class ProductListingViewModelArgs extends ViewModelArgs {
  /// Creates typed listing dependencies.
  const ProductListingViewModelArgs({required this.api, super.observer});

  /// Storefront API used by every listing route.
  final CommerceApi api;
}

/// Loads store, collection, and category routes without widget-owned data.
@ViewModel(state: ProductListingState, args: ProductListingViewModelArgs)
class ProductListingViewModel extends $ProductListingViewModel {
  /// Creates the listing state machine.
  ProductListingViewModel(super.args);

  static const _limit = 12;
  static const _sourceFetchLimit = 100;
  int _revision = 0;

  /// Loads the source `/store` route.
  Future<void> loadStore({
    int page = 1,
    String sortBy = 'created_at',
    String query = '',
    List<String> optionValueIds = const [],
    String currency = 'usd',
  }) async {
    final selected = normalizedOptionValueIds(optionValueIds);
    final search = normalizedSearchQuery(query);
    final meta = _ListingMeta(
      requestKey: listingRequestKey(
        'store',
        '',
        page,
        sortBy,
        selected,
        currency,
        search,
      ),
      title: 'All products',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
      searchQuery: search,
      selectedOptionValueIds: selected,
      currencyCode: currency,
    );
    final revision = _begin(meta);
    await _loadProducts(
      meta,
      revision,
      optionFilters: _optionalOptionFilters(args.api, _sourceFetchLimit),
    );
  }

  /// Resolves [handle] before loading its products.
  Future<void> loadCollection(
    String handle, {
    int page = 1,
    String sortBy = 'created_at',
    List<String> optionValueIds = const [],
    String currency = 'usd',
  }) async {
    final selected = normalizedOptionValueIds(optionValueIds);
    final meta = _ListingMeta(
      requestKey: listingRequestKey(
        'collection',
        handle,
        page,
        sortBy,
        selected,
        currency,
      ),
      title: '',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
      collection: Some(handle),
      selectedOptionValueIds: selected,
      currencyCode: currency,
    );
    final revision = _begin(meta);
    try {
      final result = await args.api.collections(handle: handle, limit: 1);
      if (!_active(revision)) return;
      if (result.collections.isEmpty) return _missing(meta);
      await _loadProducts(
        meta.copyWith(title: result.collections.single.title),
        revision,
      );
    } on Object {
      _fail(meta, revision);
    }
  }

  /// Resolves [handle], its hierarchy, and its products.
  Future<void> loadCategory(
    String handle, {
    int page = 1,
    String sortBy = 'created_at',
    List<String> optionValueIds = const [],
    String currency = 'usd',
  }) async {
    final selected = normalizedOptionValueIds(optionValueIds);
    final meta = _ListingMeta(
      requestKey: listingRequestKey(
        'category',
        handle,
        page,
        sortBy,
        selected,
        currency,
      ),
      title: '',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
      category: Some(handle),
      selectedOptionValueIds: selected,
      currencyCode: currency,
    );
    final revision = _begin(meta);
    try {
      final result = await args.api.categories(limit: _sourceFetchLimit);
      if (!_active(revision)) return;
      final matches = result.categories.where((it) => it.handle == handle);
      if (matches.isEmpty) return _missing(meta);
      final category = matches.single;
      await _loadProducts(
        meta.copyWith(
          title: category.name,
          description: switch (category.description) {
            final String description => description,
            null => '',
          },
          parents: _parentsOf(category, result.categories),
          children: result.categories
              .where((it) => it.parentId == category.id)
              .toList(growable: false),
        ),
        revision,
      );
    } on Object {
      _fail(meta, revision);
    }
  }

  Future<void> _loadProducts(
    _ListingMeta meta,
    int revision, {
    Future<List<ProductOptionFilterView>>? optionFilters,
  }) async {
    try {
      final productRequest = args.api.products(
        currency: meta.currencyCode,
        query: meta.searchQuery.isEmpty ? null : meta.searchQuery,
        collection: _nullable(meta.collection),
        category: _nullable(meta.category),
        optionValueIds: meta.selectedOptionValueIds,
        limit: _sourceFetchLimit,
      );
      final (result, resolvedMeta) = optionFilters == null
          ? (await productRequest, meta)
          : await _withOptionFilters(productRequest, optionFilters, meta);
      if (!_active(revision)) return;
      final sorted = _sorted(
        result.products,
        resolvedMeta.sortBy,
        resolvedMeta.currencyCode,
      );
      final start = (resolvedMeta.page - 1) * _limit;
      final end = (start + _limit).clamp(0, sorted.length);
      final products = start >= sorted.length
          ? const <Product>[]
          : sorted.sublist(start, end);
      emit(resolvedMeta.toState(
        status: ProductListingStatus.ready,
        products: products,
        totalPages: (sorted.length + _limit - 1) ~/ _limit,
      ));
    } on Object {
      _fail(meta, revision);
    }
  }

  void _setState(ProductListingState next) => emit(next);
}
