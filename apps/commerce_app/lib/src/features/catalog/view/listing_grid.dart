import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

import 'listing_pagination.dart';

/// Source grid plus pagination for a completed listing.
class ListingGrid extends StatelessWidget {
  /// Creates a responsive product grid.
  const ListingGrid({
    required this.products,
    required this.currencyCode,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
  });

  /// One-based active page.
  final int currentPage;

  /// Currency used by product cards.
  final String currencyCode;

  /// Changes the page query.
  final ValueChanged<int> onPageChanged;

  /// Products on this page.
  final List<Product> products;

  /// Number of available pages.
  final int totalPages;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 4
              : constraints.maxWidth >= 640
                  ? 3
                  : 2;
          return Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 32,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) => ProductCard(
                  product: products[index],
                  currencyCode: currencyCode,
                ),
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 48),
                ListingPagination(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPageChanged: onPageChanged,
                ),
              ],
            ],
          );
        },
      );
}
