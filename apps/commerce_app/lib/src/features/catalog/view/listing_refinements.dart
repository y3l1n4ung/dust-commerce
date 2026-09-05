import 'package:commerce_app/src/core/store_theme.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source-matched three-choice SortProducts control.
class ListingRefinements extends StatelessWidget {
  /// Creates the sort refinement list.
  const ListingRefinements({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Receives one Medusa sort query value.
  final ValueChanged<String> onChanged;

  /// Current Medusa sort query value.
  final String selected;

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
            for (final value in _choices)
              _SortChoice(
                value: value,
                label: _label(context, value),
                selected: selected == value,
                onChanged: onChanged,
              ),
          ],
        ),
      );

  String _label(BuildContext context, String value) => switch (value) {
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
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: selected
                      ? const Icon(Icons.circle, size: 8)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 7),
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
      );
}
