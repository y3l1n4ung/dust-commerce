import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

/// One frozen receipt amount with explicit discount and total treatment.
final class OrderReceiptTotalRow extends StatelessWidget {
  /// Creates a customer-facing receipt total row.
  const OrderReceiptTotalRow({
    required this.label,
    required this.value,
    this.discount = false,
    this.strong = false,
    super.key,
  });

  /// Whether the amount is shown as a subtraction.
  final bool discount;

  /// Customer-facing amount label.
  final String label;

  /// Whether the row is the final charged total.
  final bool strong;

  /// Frozen order amount.
  final Money value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
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
