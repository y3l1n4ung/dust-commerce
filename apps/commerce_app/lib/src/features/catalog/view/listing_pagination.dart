import 'package:commerce_app/src/core/store_theme.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Medusa pagination with edge pages and bounded ellipses.
class ListingPagination extends StatelessWidget {
  /// Creates a one-based pagination control.
  const ListingPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
  });

  /// Current one-based page.
  final int currentPage;

  /// Receives a selected one-based page.
  final ValueChanged<int> onPageChanged;

  /// Last one-based page.
  final int totalPages;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 12,
        children: [
          for (final item in _items(currentPage, totalPages))
            switch (item) {
              0 => const TranslatedText.dynamic(
                  'shop_pagination_ellipsis',
                  fallback: '...',
                  style: TextStyle(
                    color: StoreColors.foregroundMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              final page => TextButton(
                  onPressed:
                      page == currentPage ? null : () => onPageChanged(page),
                  style: TextButton.styleFrom(
                    foregroundColor: page == currentPage
                        ? StoreColors.foreground
                        : StoreColors.foregroundMuted,
                    disabledForegroundColor: StoreColors.foreground,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: TranslatedText.dynamic(
                    'shop_page_$page',
                    fallback: '$page',
                  ),
                ),
            },
        ],
      );
}

List<int> _items(int page, int total) {
  if (total <= 7) return [for (var value = 1; value <= total; value++) value];
  if (page <= 4) return [1, 2, 3, 4, 5, 0, total];
  if (page >= total - 3) {
    return [1, 0, for (var value = total - 4; value <= total; value++) value];
  }
  return [1, 0, page - 1, page, page + 1, 0, total];
}
