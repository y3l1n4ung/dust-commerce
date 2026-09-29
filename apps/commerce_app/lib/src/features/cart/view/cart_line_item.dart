import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// One source-faithful cart table row.
class CartLineItem extends StatelessWidget {
  /// Creates a cart row.
  const CartLineItem({
    required this.item,
    required this.state,
    required this.wide,
    required this.showDivider,
    super.key,
  });

  /// Snapshotted product line.
  final LineItem item;

  /// Current cart mutation state.
  final CartState state;

  /// Whether all source table columns fit.
  final bool wide;

  /// Whether this non-final row retains the source table divider.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final busy = state.status == CartStatus.loading;
    final active = busy && state.activeLineId == item.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LineImage(item: item, wide: wide),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: wide ? 22 : 8),
                  child: _LineIdentity(item: item),
                ),
              ),
              SizedBox(
                width: wide ? 168 : 112,
                child: _QuantityControl(
                  item: item,
                  enabled: !busy,
                  active: active,
                ),
              ),
              if (wide)
                SizedBox(width: 80, child: Text(formatMoney(item.unitPrice))),
              SizedBox(
                width: 88,
                child: Text(
                  formatMoney(item.subtotal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (state.status == CartStatus.failed && state.activeLineId == item.id)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.message ??
                  context.tr(
                    'shop_cart_update_failed',
                    defaultText: 'Could not update this item.',
                  ),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

class _LineImage extends StatelessWidget {
  const _LineImage({required this.item, required this.wide});

  final LineItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: wide ? 104 : 64,
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () =>
                context.navigator.product(handle: item.productHandle).push(),
            child: SizedBox(
              width: wide ? 96 : 48,
              child: ProductImage(url: item.thumbnail, aspectRatio: 1),
            ),
          ),
        ),
      );
}

class _LineIdentity extends StatelessWidget {
  const _LineIdentity({required this.item});

  final LineItem item;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (item.variantTitle case final title?)
            Text(
              context.tr(
                'shop_cart_variant',
                defaultText: 'Variant: {name}',
                args: {'name': title},
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: StoreColors.foregroundMuted),
            ),
        ],
      );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.item,
    required this.enabled,
    required this.active,
  });

  final bool active;
  final bool enabled;
  final LineItem item;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled
                ? () => context.readCartViewModel().remove(item.id)
                : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: context.tr('shop_cart_remove', defaultText: 'Remove'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
          ),
          Container(
            width: 56,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: StoreColors.subtleHover,
              border: Border.all(color: StoreColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: item.quantity.clamp(1, 10),
                isExpanded: true,
                onChanged: enabled ? (value) => _update(context, value) : null,
                items: [
                  for (var quantity = 1; quantity <= 10; quantity++)
                    DropdownMenuItem(value: quantity, child: Text('$quantity')),
                ],
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      );

  void _update(BuildContext context, int? value) {
    if (value == null || value == item.quantity) return;
    context.readCartViewModel().updateQuantity(item.id, value);
  }
}
