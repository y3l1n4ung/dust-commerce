import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source home ProductRail backed by one real collection filter.
class FeaturedProductRailView extends StatelessWidget {
  /// Creates a collection rail.
  const FeaturedProductRailView({
    required this.rail,
    required this.currencyCode,
    super.key,
  });

  /// Currency used by every product card.
  final String currencyCode;

  /// Collection and products loaded together by the home state machine.
  final FeaturedProductRail rail;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: MediaQuery.sizeOf(context).width >= 1024 ? 96 : 48,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TranslatedText.dynamic(
                      'shop_collection_${rail.collection.id}',
                      fallback: rail.collection.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () => context.navigator
                          .collection(handle: rail.collection.handle)
                          .go(),
                      style: TextButton.styleFrom(
                        foregroundColor: StoreColors.interactive,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_outward, size: 16),
                      label: const TranslatedText(
                        'shop_view_all',
                        defaultText: 'View all',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 976 ? 3 : 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: constraints.maxWidth >= 976 ? 144 : 96,
                    ),
                    itemCount: rail.products.length,
                    itemBuilder: (_, index) => ProductCard(
                      product: rail.products[index],
                      currencyCode: currencyCode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
