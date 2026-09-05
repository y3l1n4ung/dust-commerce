import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Variant controls translated from Medusa DTC ProductActions.
class ProductActions extends StatelessWidget {
  /// Creates controls for the loaded product [state].
  const ProductActions({required this.state, super.key});

  /// Product and option selection currently visible on the detail route.
  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final product = state.product!;
    final selected = state.selectedVariant;
    final price = selected?.priceIn('usd');
    final cart = context.watchCartViewModel().value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in product.options) ...[
          Text(
            context.tr(
              'shop_select_option',
              defaultText: 'Select {name}',
              args: {'name': option.title},
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in option.values)
                ChoiceChip(
                  label: Text(value),
                  selected: state.selection[option.id] == value,
                  onSelected: (_) =>
                      context.readProductViewModel().select(option.id, value),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(
          price == null
              ? context.tr('shop_select_variant', defaultText: 'Select variant')
              : formatMoney(price),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: selected == null ||
                  !selected.isInStock ||
                  cart.status == CartStatus.loading
              ? null
              : () => _add(context, selected),
          child: Text(
            selected == null
                ? context.tr(
                    'shop_select_variant',
                    defaultText: 'Select variant',
                  )
                : selected.isInStock
                    ? context.tr(
                        'shop_add_to_cart',
                        defaultText: 'Add to cart',
                      )
                    : context.tr(
                        'shop_out_of_stock',
                        defaultText: 'Out of stock',
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, ProductVariant variant) async {
    final added = await context.readCartViewModel().add(variant);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? context.tr('shop_added_to_cart', defaultText: 'Added to cart')
              : context.tr(
                  'shop_add_to_cart_failed',
                  defaultText: 'Could not add to cart',
                ),
        ),
      ),
    );
  }
}
