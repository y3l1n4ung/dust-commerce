import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// One item in the desktop navigation cart preview.
class CartPreviewLine extends StatelessWidget {
  /// Creates a compact preview line.
  const CartPreviewLine({
    required this.item,
    required this.state,
    required this.onClose,
    super.key,
  });

  /// Product snapshot held by the cart.
  final LineItem item;

  /// Closes the preview before product navigation.
  final VoidCallback onClose;

  /// Current mutation state.
  final CartState state;

  @override
  Widget build(BuildContext context) {
    final deleting = state.status == CartStatus.loading &&
        state.operation == CartOperation.remove &&
        state.activeLineId == item.id;
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _product(context),
            child: SizedBox.square(
              dimension: 96,
              child: ProductImage(url: item.thumbnail, aspectRatio: 1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _product(context),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formatMoney(item.subtotal)),
                  ],
                ),
                if (item.variantTitle case final title?)
                  Text(
                    context.tr(
                      'shop_cart_variant',
                      defaultText: 'Variant: {name}',
                      args: {'name': title},
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StoreColors.foregroundSubtle,
                    ),
                  ),
                Text(
                  context.tr(
                    'shop_cart_preview_quantity',
                    defaultText: 'Quantity: {count}',
                    args: {'count': item.quantity},
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: state.status == CartStatus.loading
                      ? null
                      : () => context.readCartViewModel().remove(item.id),
                  icon: deleting
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 16),
                  label: const TranslatedText(
                    'shop_cart_remove',
                    defaultText: 'Remove',
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _product(BuildContext context) {
    onClose();
    context.navigator.product(handle: item.productHandle).push();
  }
}
