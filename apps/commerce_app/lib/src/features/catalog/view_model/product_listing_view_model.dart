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
  Future<void> loadStore({int page = 1, String sortBy = 'created_at'}) async {
    final meta = _ListingMeta(
      requestKey: listingRequestKey('store', '', page, sortBy),
      title: 'All products',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
    );
    await _loadProducts(meta, _begin(meta));
  }

  /// Resolves [handle] before loading its products.
  Future<void> loadCollection(
    String handle, {
    int page = 1,
    String sortBy = 'created_at',
  }) async {
    final meta = _ListingMeta(
      requestKey: listingRequestKey('collection', handle, page, sortBy),
      title: '',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
      collection: Some(handle),
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
  }) async {
    final meta = _ListingMeta(
      requestKey: listingRequestKey('category', handle, page, sortBy),
      title: '',
      page: page < 1 ? 1 : page,
      sortBy: normalizedProductSort(sortBy),
      category: Some(handle),
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

  Future<void> _loadProducts(_ListingMeta meta, int revision) async {
    try {
      final result = await args.api.products(
        currency: meta.currencyCode,
        collection: _nullable(meta.collection),
        category: _nullable(meta.category),
        limit: _sourceFetchLimit,
      );
      if (!_active(revision)) return;
      final sorted = _sorted(
        result.products,
        meta.sortBy,
        meta.currencyCode,
      );
      final start = (meta.page - 1) * _limit;
      final end = (start + _limit).clamp(0, sorted.length);
      final products = start >= sorted.length
          ? const <Product>[]
          : sorted.sublist(start, end);
      emit(meta.toState(
        status: ProductListingStatus.ready,
        products: products,
        totalPages: (sorted.length + _limit - 1) ~/ _limit,
      ));
    } on Object {
      _fail(meta, revision);
    }
  }

  int _begin(_ListingMeta meta) {
    final revision = ++_revision;
    emit(meta.toState(status: ProductListingStatus.loading));
    return revision;
  }

  bool _active(int revision) => revision == _revision;

  void _missing(_ListingMeta meta) =>
      emit(meta.toState(status: ProductListingStatus.missing));

  void _fail(_ListingMeta meta, int revision) {
    if (!_active(revision)) return;
    emit(meta.toState(
      status: ProductListingStatus.failed,
    ));
  }
}
