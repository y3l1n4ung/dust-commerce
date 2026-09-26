import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/fp.dart';
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
    this.category = const [],
    this.labels = const [],
    this.maxPrice,
    this.minPrice,
    super.key,
  });

  /// Stable category handles repeated in the URL query.
  final List<String> category;

  /// Stable product label values repeated in the URL query.
  final List<String> labels;

  /// Upper price bound in minor units.
  final int? maxPrice;

  /// Lower price bound in minor units.
  final int? minPrice;

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
    final selectedCategories = normalizedCategoryHandles(category);
    final selectedLabels = normalizedLabelValues(labels);
    final selectedMinPrice = normalizedPriceBoundary(minPrice);
    final selectedMaxPrice = normalizedPriceBoundary(maxPrice);
    final currency = context.watchStoreShellViewModel().value.currencyCode;
    final requestKey = listingRequestKey(
      'store',
      '',
      currentPage,
      currentSort,
      selected,
      selectedCategories,
      selectedLabels,
      currency,
      currentQuery,
      selectedMinPrice,
      selectedMaxPrice,
    );
    return ProductListingRoute(
      key: ValueKey(requestKey),
      requestKey: requestKey,
      load: (viewModel) => viewModel.loadStore(
        page: currentPage,
        query: currentQuery,
        sortBy: currentSort,
        optionValueIds: selected,
        categoryHandles: selectedCategories,
        labels: selectedLabels,
        maxPrice: selectedMaxPrice,
        minPrice: selectedMinPrice,
        currency: currency,
      ),
      onSortChanged: (value) => context.navigator
          .store(
            q: currentQuery,
            sortBy: value,
            optionValueIds: selected,
            category: selectedCategories,
            labels: selectedLabels,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onSearchChanged: (value) => context.navigator
          .store(
            q: normalizedSearchQuery(value),
            sortBy: currentSort,
            optionValueIds: selected,
            category: selectedCategories,
            labels: selectedLabels,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onPageChanged: (value) => context.navigator
          .store(
            q: currentQuery,
            page: value,
            sortBy: currentSort,
            optionValueIds: selected,
            category: selectedCategories,
            labels: selectedLabels,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onOptionValuesChanged: (values) => context.navigator
          .store(
            q: currentQuery,
            sortBy: currentSort,
            optionValueIds: values,
            category: selectedCategories,
            labels: selectedLabels,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onCategoryHandlesChanged: (values) => context.navigator
          .store(
            q: currentQuery,
            sortBy: currentSort,
            optionValueIds: selected,
            category: values,
            labels: selectedLabels,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onLabelValuesChanged: (values) => context.navigator
          .store(
            q: currentQuery,
            sortBy: currentSort,
            optionValueIds: selected,
            category: selectedCategories,
            labels: values,
            maxPrice: _valueOf(selectedMaxPrice),
            minPrice: _valueOf(selectedMinPrice),
          )
          .go(),
      onPriceRangeChanged: (minPrice, maxPrice) => context.navigator
          .store(
            q: currentQuery,
            sortBy: currentSort,
            optionValueIds: selected,
            category: selectedCategories,
            labels: selectedLabels,
            maxPrice: maxPrice,
            minPrice: minPrice,
          )
          .go(),
      onCategorySelected: (handle) =>
          context.navigator.category(handle: handle).go(),
    );
  }

  int? _valueOf(Option<int> value) => switch (value) {
        Some(:final value) => value,
        None() => null,
      };
}
