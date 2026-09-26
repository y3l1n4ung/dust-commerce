import 'package:commerce_app/src/core/product_image.dart';
import 'package:commerce_app/src/core/store_theme.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Search input matching the Medusa drawer and Store search boxes.
final class StoreSearchField extends StatelessWidget {
  /// Creates the search field.
  const StoreSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  /// Text controller owned by the drawer.
  final TextEditingController controller;

  /// Debounced upstream change callback.
  final ValueChanged<String> onChanged;

  /// Clears the current query.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
        autofocus: true,
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: StoreColors.foregroundMuted,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.tr(
                    'shop_search_clear',
                    defaultText: 'Clear search',
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
          hintText: context.tr(
            'shop_search_products',
            defaultText: 'Search products',
          ),
          border: const UnderlineInputBorder(),
        ),
        onChanged: onChanged,
      );
}

/// Search result, loading, empty, and error states.
final class StoreSearchBody extends StatelessWidget {
  /// Creates the drawer body.
  const StoreSearchBody({
    required this.failed,
    required this.hits,
    required this.loading,
    required this.query,
    required this.searched,
    required this.onProductSelected,
    super.key,
  });

  /// Whether the last search request failed.
  final bool failed;

  /// Products returned for the current query.
  final List<Product> hits;

  /// Whether the search request is in flight.
  final bool loading;

  /// Opens a selected product handle.
  final ValueChanged<String> onProductSelected;

  /// Current trimmed query.
  final String query;

  /// Whether the customer has typed a query yet.
  final bool searched;

  @override
  Widget build(BuildContext context) {
    if (!searched) {
      return const _StoreSearchMessage(
        child: TranslatedText(
          'shop_search_start',
          defaultText: 'Start typing to search for products.',
        ),
      );
    }
    if (loading) {
      return const _StoreSearchMessage(
        child: TranslatedText(
          'shop_search_loading',
          defaultText: 'Searching…',
        ),
      );
    }
    if (failed) {
      return const _StoreSearchMessage(
        child: TranslatedText(
          'shop_search_failed',
          defaultText: 'Could not search products.',
        ),
      );
    }
    if (hits.isEmpty) return _StoreSearchEmpty(query: query);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: hits.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _StoreSearchHit(
        product: hits[index],
        onSelected: onProductSelected,
      ),
    );
  }
}

final class _StoreSearchHit extends StatelessWidget {
  const _StoreSearchHit({required this.product, required this.onSelected});

  final ValueChanged<String> onSelected;
  final Product product;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: product.title,
        onTap: () => onSelected(product.handle),
        child: ExcludeSemantics(
          child: InkWell(
            onTap: () => onSelected(product.handle),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: ProductImage(
                      url: product.thumbnail,
                      aspectRatio: 7 / 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

final class _StoreSearchEmpty extends StatelessWidget {
  const _StoreSearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '${context.tr(
            'shop_search_empty',
            defaultText: 'No products found for',
          )} "$query"',
          style: const TextStyle(color: StoreColors.foregroundSubtle),
        ),
      );
}

final class _StoreSearchMessage extends StatelessWidget {
  const _StoreSearchMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: StoreColors.foregroundSubtle),
          child: child,
        ),
      );
}
