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
    this.q = '',
    this.sortBy = 'created_at',
    this.optionValueIds = const [],
    super.key,
  });

  /// Stable option-value identifiers repeated in the URL query.
  final List<String> optionValueIds;

  /// One-based page query.
  final int page;

  /// Free-text product search query.
  final String q;

  /// Medusa-compatible sort query.
  final String sortBy;

  @override
  Widget build(BuildContext context) {
    final currentPage = page < 1 ? 1 : page;
    final currentQuery = normalizedSearchQuery(q);
    final currentSort = normalizedProductSort(sortBy);
    final selected = normalizedOptionValueIds(optionValueIds);
    final currency = context.watchStoreShellViewModel().value.currencyCode;
    final requestKey = listingRequestKey(
      'store',
      '',
      currentPage,
      currentSort,
      selected,
      currency,
      currentQuery,
    );
    return ProductListingRoute(
      key: ValueKey(requestKey),
      requestKey: requestKey,
      load: (viewModel) => viewModel.loadStore(
        page: currentPage,
        query: currentQuery,
        sortBy: currentSort,
        optionValueIds: selected,
        currency: currency,
      ),
      onSortChanged: (value) => context.navigator
          .store(q: currentQuery, sortBy: value, optionValueIds: selected)
          .go(),
      onSearchChanged: (value) => context.navigator
          .store(
            q: normalizedSearchQuery(value),
            sortBy: currentSort,
            optionValueIds: selected,
          )
          .go(),
      onPageChanged: (value) => context.navigator
          .store(
            q: currentQuery,
            page: value,
            sortBy: currentSort,
            optionValueIds: selected,
          )
          .go(),
      onOptionValuesChanged: (values) => context.navigator
          .store(q: currentQuery, sortBy: currentSort, optionValueIds: values)
          .go(),
      onCategorySelected: (handle) =>
          context.navigator.category(handle: handle).go(),
    );
  }
}
