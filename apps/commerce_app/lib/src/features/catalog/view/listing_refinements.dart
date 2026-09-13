import 'package:commerce_app/src/core/store_theme.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'listing_option_filters.dart';

/// Source-matched three-choice SortProducts control.
class ListingRefinements extends StatelessWidget {
  /// Creates the sort refinement list.
  const ListingRefinements({
    required this.selected,
    required this.onChanged,
    required this.options,
    required this.selectedOptionValueIds,
    required this.onOptionValuesChanged,
    super.key,
  });

  /// Receives one Medusa sort query value.
  final ValueChanged<String> onChanged;

  /// Replaces the repeated option-value query.
  final ValueChanged<List<String>> onOptionValuesChanged;

  /// Store-only option axes discovered from the backend.
  final List<ProductOptionFilterView> options;

  /// Current Medusa sort query value.
  final String selected;

  /// Stable option-value identifiers currently selected.
  final List<String> selectedOptionValueIds;

  static const _choices = <String>[
    'created_at',
    'price_asc',
    'price_desc',
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SortProducts(
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
          ],
        ),
      );

  static String _label(BuildContext context, String value) => switch (value) {
        'price_asc' => context.tr(
            'shop_sort_price_asc',
            defaultText: 'Price: Low -> High',
          ),
        'price_desc' => context.tr(
            'shop_sort_price_desc',
            defaultText: 'Price: High -> Low',
          ),
        _ => context.tr(
            'shop_sort_latest',
            defaultText: 'Latest Arrivals',
          ),
      };
}

class _SortProducts extends StatelessWidget {
  const _SortProducts({required this.selected, required this.onChanged});

  final ValueChanged<String> onChanged;
  final String selected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'shop_sort_by',
            defaultText: 'Sort by',
            style: TextStyle(
              color: StoreColors.foregroundMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final value in ListingRefinements._choices)
            _SortChoice(
              value: value,
              label: ListingRefinements._label(context, value),
              selected: selected == value,
              onChanged: onChanged,
            ),
        ],
      );
}

class _SortChoice extends StatelessWidget {
  const _SortChoice({
    required this.value,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final bool selected;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: selected ? null : () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Transform.translate(
              offset: selected ? const Offset(-23, 0) : Offset.zero,
              child: Row(
                children: [
                  if (selected) ...[
                    const SizedBox(
                      width: 16,
                      child: Icon(Icons.circle, size: 8),
                    ),
                    const SizedBox(width: 7),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? StoreColors.foreground
                          : StoreColors.foregroundSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
