import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter/material.dart';

import 'product_listing_route.dart';

/// Curated collection page translated from Medusa CollectionTemplate.
@AppRoute('/collections/:handle', name: 'collection', guards: [])
class CollectionPage extends StatelessWidget {
  /// Creates a paged collection route.
  const CollectionPage({
    required this.handle,
    this.page = 1,
    this.sortBy = 'created_at',
    super.key,
  });

  /// Stable collection handle from the URL.
  final String handle;

  /// One-based page query.
  final int page;

  /// Medusa-compatible sort query.
  final String sortBy;

  @override
  Widget build(BuildContext context) {
    final currentPage = page < 1 ? 1 : page;
    final currentSort = normalizedProductSort(sortBy);
    final requestKey = listingRequestKey(
      'collection',
      handle,
      currentPage,
      currentSort,
    );
    return ProductListingRoute(
      key: ValueKey(requestKey),
      requestKey: requestKey,
      load: (viewModel) => viewModel.loadCollection(
        handle,
        page: currentPage,
        sortBy: currentSort,
      ),
      onSortChanged: (value) =>
          context.navigator.collection(handle: handle, sortBy: value).go(),
      onPageChanged: (value) => context.navigator
          .collection(handle: handle, page: value, sortBy: currentSort)
          .go(),
      onCategorySelected: (categoryHandle) =>
          context.navigator.category(handle: categoryHandle).go(),
    );
  }
}
