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
    this.optionValueIds = const [],
    super.key,
  });

  /// Stable option-value identifiers repeated in the URL query.
  final List<String> optionValueIds;

  /// One-based page query.
  final int page;

  /// Medusa-compatible sort query.
  final String sortBy;

  @override
  Widget build(BuildContext context) {
    final currentPage = page < 1 ? 1 : page;
    final currentSort = normalizedProductSort(sortBy);
    final selected = normalizedOptionValueIds(optionValueIds);
    final requestKey = listingRequestKey(
      'store',
      '',
      currentPage,
      currentSort,
      selected,
    );
    return ProductListingRoute(
      key: ValueKey(requestKey),
      requestKey: requestKey,
      load: (viewModel) => viewModel.loadStore(
        page: currentPage,
        sortBy: currentSort,
        optionValueIds: selected,
      ),
      onSortChanged: (value) =>
          context.navigator.store(sortBy: value, optionValueIds: selected).go(),
      onPageChanged: (value) => context.navigator
          .store(
            page: value,
            sortBy: currentSort,
            optionValueIds: selected,
          )
          .go(),
      onOptionValuesChanged: (values) => context.navigator
          .store(sortBy: currentSort, optionValueIds: values)
          .go(),
      onCategorySelected: (handle) =>
          context.navigator.category(handle: handle).go(),
    );
  }
}
