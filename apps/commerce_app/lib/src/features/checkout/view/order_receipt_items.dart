import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Immutable line snapshots shown on the confirmation receipt.
final class OrderReceiptItems extends StatelessWidget {
  /// Creates the order line list.
  const OrderReceiptItems({required this.order, super.key});

  /// Frozen paid order.
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final item in order.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 96,
                  child: ProductImage(url: item.thumbnail, aspectRatio: 1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.variantTitle case final title?) Text(title),
                      Text(context.tr(
                        'shop_checkout_quantity',
                        defaultText: 'Quantity: {count}',
                        args: {'count': item.quantity},
                      )),
                    ],
                  ),
                ),
                Text(formatMoney(item.subtotal)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
        ],
      );
}

/// Frozen order totals; never recalculated from current catalogue data.
final class OrderReceiptTotals extends StatelessWidget {
  /// Creates receipt totals.
  const OrderReceiptTotals({required this.order, super.key});

  /// Frozen paid order.
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row(context.tr('shop_checkout_subtotal', defaultText: 'Subtotal'),
              order.subtotal),
          _row(context.tr('shop_checkout_shipping', defaultText: 'Shipping'),
              order.shippingTotal),
          if (!order.discountTotal.isZero)
            _row(context.tr('shop_checkout_discount', defaultText: 'Discount'),
                order.discountTotal,
                discount: true),
          _row(context.tr('shop_checkout_taxes', defaultText: 'Taxes'),
              order.tax),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _row(context.tr('shop_checkout_total', defaultText: 'Total'),
              order.total,
              strong: true),
        ],
      );

  Widget _row(String label, Money value,
          {bool discount = false, bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontWeight: strong ? FontWeight.w600 : null)),
            Text(
              '${discount ? '- ' : ''}${formatMoney(value)}',
              style: TextStyle(
                color: discount ? StoreColors.interactive : null,
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      );
}
