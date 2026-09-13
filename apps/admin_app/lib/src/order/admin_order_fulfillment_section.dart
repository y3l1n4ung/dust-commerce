import 'package:admin_app/src/order/admin_order_status_badge.dart';
import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Honest fulfillment state while fulfillment operations are not modeled.
final class AdminOrderFulfillmentSection extends StatelessWidget {
  /// Creates the fulfillment section.
  const AdminOrderFulfillmentSection({required this.order, super.key});

  /// Complete merchant order snapshot.
  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: 'Fulfillment',
        action: AdminOrderFulfillmentBadge(status: order.fulfillmentStatus),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No fulfillments have been created.'),
              if (order.shippingName case Some(value: final name)) ...[
                const SizedBox(height: 6),
                Text(
                  'Shipping method: $name',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
