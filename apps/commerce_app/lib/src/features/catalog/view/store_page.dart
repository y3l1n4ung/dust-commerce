import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter/material.dart';

import 'product_listing_route.dart';

/// All-products page translated from Medusa StoreTemplate.
@AppRoute('/store', name: 'store', guards: [])
class StorePage extends StatelessWidget {
  /// Creates the paged store route.
  const StorePage({
    this.page = 1,
    this.sortBy = 'created_at',
    super.key,
  });

  /// One-based page query.
  final int page;

  /// Medusa-compatible sort query.
  final String sortBy;

  @override
  Widget build(BuildContext context) {
    final currentPage = page < 1 ? 1 : page;
    final currentSort = normalizedProductSort(sortBy);
    final requestKey = listingRequestKey('store', '', currentPage, currentSort);
    return ProductListingRoute(
      key: ValueKey(requestKey),
      requestKey: requestKey,
      load: (viewModel) => viewModel.loadStore(
        page: currentPage,
        sortBy: currentSort,
      ),
      onSortChanged: (value) => context.navigator.store(sortBy: value).go(),
      onPageChanged: (value) =>
          context.navigator.store(page: value, sortBy: currentSort).go(),
      onCategorySelected: (handle) =>
          context.navigator.category(handle: handle).go(),
    );
  }
}
