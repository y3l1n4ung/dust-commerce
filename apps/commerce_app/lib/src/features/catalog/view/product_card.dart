import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// ProductPreview translated from the Medusa DTC source.
class ProductCard extends StatelessWidget {
  /// Creates a product card.
  const ProductCard({
    required this.product,
    required this.currencyCode,
    super.key,
  });

  /// Currency selected by the catalogue.
  final String currencyCode;

  /// Product rendered by this card.
  final Product product;

  @override
  Widget build(BuildContext context) {
    final price = product.cheapestIn(currencyCode);
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
            ProductImage(url: product.thumbnail),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: const TextStyle(color: Color(0xff52525b)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price == null ? '—' : formatMoney(price),
                  style: const TextStyle(color: Color(0xff71717a)),
                ),
              ],
            ),
            if (!product.isPurchasable)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: TranslatedText(
                  'shop_sold_out',
                  defaultText: 'Sold out',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
