import 'package:commerce_app/src/features/catalog/model/product_listing_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

import 'listing_category_filters.dart';
import 'listing_label_filters.dart';
import 'listing_option_filters.dart';
import 'listing_price_range.dart';
import 'listing_sort_products.dart';

/// Source-matched three-choice SortProducts control.
class ListingRefinements extends StatelessWidget {
  /// Creates the sort refinement list.
  const ListingRefinements({
    required this.selected,
    required this.onChanged,
    required this.options,
    required this.selectedOptionValueIds,
    required this.onOptionValuesChanged,
    required this.categoryFilters,
    required this.selectedCategoryHandles,
    required this.labelFilters,
    required this.selectedLabelValues,
    required this.priceBounds,
    required this.selectedMaxPrice,
    required this.selectedMinPrice,
    required this.currencyCode,
    this.onCategoryHandlesChanged,
    this.onLabelValuesChanged,
    this.onPriceRangeChanged,
    super.key,
  });

  /// Store-only category refinements discovered from matching products.
  final List<ProductCategoryFilter> categoryFilters;

  /// Currency used by price-range labels.
  final String currencyCode;

  /// Replaces the repeated category query.
  final ValueChanged<List<String>>? onCategoryHandlesChanged;

  /// Store-only label refinements discovered from matching products.
  final List<ProductLabelFilter> labelFilters;

  /// Replaces the repeated labels query.
  final ValueChanged<List<String>>? onLabelValuesChanged;

  /// Receives one Medusa sort query value.
  final ValueChanged<String> onChanged;

  /// Replaces the repeated option-value query.
  final ValueChanged<List<String>> onOptionValuesChanged;

  /// Replaces the price range query.
  final void Function(int? minPrice, int? maxPrice)? onPriceRangeChanged;

  /// Store-only option axes discovered from the backend.
  final List<ProductOptionFilterView> options;

  /// Store-only price bounds discovered from matching products.
  final Option<ProductPriceBounds> priceBounds;

  /// Current Medusa sort query value.
  final String selected;

  /// Stable category handles currently selected.
  final List<String> selectedCategoryHandles;

  /// Stable label values currently selected.
  final List<String> selectedLabelValues;

  /// Active upper price bound in minor units.
  final Option<int> selectedMaxPrice;

  /// Active lower price bound in minor units.
  final Option<int> selectedMinPrice;

  /// Stable option-value identifiers currently selected.
  final List<String> selectedOptionValueIds;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SortProducts(
              selected: selected,
              onChanged: onChanged,
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 48),
              ListingOptionFilters(
                options: options,
                selectedValueIds: selectedOptionValueIds,
                onChanged: onOptionValuesChanged,
              ),
            ],
            if (onPriceRangeChanged case final onChanged?) ...[
              const SizedBox(height: 48),
              ListingPriceRange(
                bounds: priceBounds,
                currencyCode: currencyCode,
                selectedMaxPrice: selectedMaxPrice,
                selectedMinPrice: selectedMinPrice,
                onChanged: onChanged,
              ),
            ],
            if (onCategoryHandlesChanged case final onChanged?
                when categoryFilters.isNotEmpty) ...[
              const SizedBox(height: 48),
              ListingCategoryFilters(
                categories: categoryFilters,
                selectedHandles: selectedCategoryHandles,
                onChanged: onChanged,
              ),
            ],
            if (onLabelValuesChanged case final onChanged?
                when labelFilters.isNotEmpty) ...[
              const SizedBox(height: 48),
              ListingLabelFilters(
                labels: labelFilters,
                selectedValues: selectedLabelValues,
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      );
}
