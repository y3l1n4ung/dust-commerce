import 'package:commerce_app/src/features/product/view/product_tabs.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

/// Product title, description, and accordions from Medusa `ProductInfo`.
class ProductInfo extends StatelessWidget {
  /// Creates product information for [product].
  const ProductInfo({required this.product, super.key});

  /// Loaded storefront product.
  final Product product;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            product.description ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ProductTabs(details: product.details),
        ],
      );
}
