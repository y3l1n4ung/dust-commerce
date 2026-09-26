import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

/// ProductPreview translated from the Medusa DTC source.
class ProductCard extends StatelessWidget {
  /// Creates a product card.
  const ProductCard({
    required this.product,
    required this.currencyCode,
    this.featured = false,
    super.key,
  });

  /// Currency selected by the catalogue.
  final String currencyCode;

  /// Whether this card uses the wider home-rail image ratio.
  final bool featured;

  /// Product rendered by this card.
  final Product product;

  @override
  Widget build(BuildContext context) {
    final price = product.cheapestIn(currencyCode);
    final original = product.cheapestOriginalIn(currencyCode);
    final readablePrice = price == null ? 'unavailable' : formatMoney(price);
    return Semantics(
      button: true,
      label: '${product.title}, $readablePrice',
      child: InkWell(
        onTap: () => context.navigator.product(handle: product.handle).push(),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductImage(
              url: product.previewImageUrl,
              aspectRatio: featured ? 11 / 14 : 9 / 16,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: const TextStyle(color: StoreColors.foregroundSubtle),
                  ),
                ),
                const SizedBox(width: 8),
                if (price != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (original != null)
                        Text(
                          formatMoney(original),
                          style: const TextStyle(
                            color: StoreColors.foregroundMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        formatMoney(price),
                        style: TextStyle(
                          color: original == null
                              ? StoreColors.foregroundMuted
                              : StoreColors.interactive,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
