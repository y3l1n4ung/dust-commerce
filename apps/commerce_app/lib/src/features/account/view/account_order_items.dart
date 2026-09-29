import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

/// Frozen order-line table translated from Medusa's order Items component.
final class AccountOrderItems extends StatelessWidget {
  /// Creates a complete order-line list.
  const AccountOrderItems({required this.order, super.key});

  /// Customer-owned frozen order.
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final item in order.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 64,
                    child: ProductImage(url: item.thumbnail, aspectRatio: 1),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.variantTitle case final title?)
                          Text(
                            title,
                            style: const TextStyle(
                              color: StoreColors.foregroundSubtle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantity}x ${formatMoney(item.unitPrice)}',
                        style: const TextStyle(
                          color: StoreColors.foregroundMuted,
                        ),
                      ),
                      Text(formatMoney(item.subtotal)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      );
}
