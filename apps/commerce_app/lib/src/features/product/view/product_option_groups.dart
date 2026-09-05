import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Medusa option axes shared by inline and sticky-mobile purchase controls.
class ProductOptionGroups extends StatelessWidget {
  /// Creates option groups for the current product [state].
  const ProductOptionGroups({
    required this.state,
    this.disabled = false,
    super.key,
  });

  /// Whether an add-to-cart request temporarily blocks option changes.
  final bool disabled;

  /// Current product and option selection.
  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final product = state.product!;
    if (product.variants.length <= 1) return const SizedBox.shrink();
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
              for (var valueIndex = 0;
                  valueIndex < option.values.length;
                  valueIndex++) ...[
                Expanded(
                  child: ProductOptionButton(
                    label: option.values[valueIndex],
                    selected:
                        state.selection[option.id] == option.values[valueIndex],
                    onPressed: disabled ||
                            !state.canSelect(
                                option.id, option.values[valueIndex])
                        ? null
                        : () => _select(
                              context,
                              product.handle,
                              option.id,
                              option.values[valueIndex],
                            ),
                  ),
                ),
                if (valueIndex != option.values.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          if (option.id != product.options.last.id) const SizedBox(height: 24),
        ],
      ],
    );
  }

  void _select(
    BuildContext context,
    String handle,
    String optionId,
    String value,
  ) {
    final viewModel = context.readProductViewModel()..select(optionId, value);
    final variantId = viewModel.state.selectedVariant?.id;
    if (context.productVariantId != variantId) {
      context.replaceProductVariant(handle, variantId);
    }
  }
}
