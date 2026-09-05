import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_app/src/features/product/view/product_option_button.dart';
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
    final price = selected?.priceIn('usd') ?? product.cheapestIn('usd');
    final cart = context.watchCartViewModel().value;
    final busy = cart.status == CartStatus.loading;
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
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < option.values.length; index++) ...[
                Expanded(
                  child: ProductOptionButton(
                    label: option.values[index],
                    selected:
                        state.selection[option.id] == option.values[index],
                    onPressed: busy ||
                            !state.canSelect(option.id, option.values[index])
                        ? null
                        : () => _select(
                              context,
                              product,
                              option.id,
                              option.values[index],
                            ),
                  ),
                ),
                if (index != option.values.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(
          price == null
              ? '-'
              : '${selected == null ? context.tr('shop_from_price', defaultText: 'From ') : ''}${formatMoney(price)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: selected == null || !selected.isInStock || busy
              ? null
              : () => _add(context, selected),
          child: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
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

  void _select(
    BuildContext context,
    Product product,
    String optionId,
    String value,
  ) {
    final viewModel = context.readProductViewModel()..select(optionId, value);
    context.replaceProductVariant(
        product.handle, viewModel.state.selectedVariant?.id);
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
