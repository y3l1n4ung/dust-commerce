import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'order_receipt_details.dart';
import 'order_receipt_items.dart';

/// Full Medusa order-completed template rendered from a frozen receipt.
final class OrderConfirmationView extends StatelessWidget {
  /// Creates the completed order view.
  const OrderConfirmationView({required this.order, super.key});

  /// Frozen paid order shown as the receipt.
  final Order order;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 896),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TranslatedText(
                          'shop_checkout_thank_you',
                          defaultText:
                              'Thank you!\nYour order was placed successfully.',
                          style: TextStyle(fontSize: 30, height: 1.35),
                        ),
                        const SizedBox(height: 16),
                        Text(context.tr(
                          'shop_checkout_confirmation_sent',
                          defaultText:
                              'We have sent the order confirmation details to {email}.',
                          args: {'email': order.email},
                        )),
                        const SizedBox(height: 8),
                        Text(context.tr(
                          'shop_checkout_order_date',
                          defaultText: 'Order date: {date}',
                          args: {'date': _date(order.placedAt)},
                        )),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            'shop_checkout_order_number',
                            defaultText: 'Order number: {id}',
                            args: {'id': order.id},
                          ),
                          style:
                              const TextStyle(color: StoreColors.interactive),
                        ),
                        const SizedBox(height: 32),
                        const TranslatedText(
                          'shop_checkout_summary',
                          defaultText: 'Summary',
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 24),
                        OrderReceiptItems(order: order),
                        const SizedBox(height: 24),
                        OrderReceiptTotals(order: order),
                        const SizedBox(height: 40),
                        OrderShippingDetails(order: order),
                        const SizedBox(height: 40),
                        OrderPaymentDetails(order: order),
                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 24),
                        const TranslatedText(
                          'shop_checkout_need_help',
                          defaultText: 'Need help?',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const TranslatedText(
                          'shop_checkout_help_body',
                          defaultText:
                              'If you have questions about your order, contact our '
                              'customer service team.',
                          style: TextStyle(color: StoreColors.foregroundSubtle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const StoreFooter(),
          ],
        ),
      );

  static String _date(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    return '${weekdays[local.weekday - 1]} ${months[local.month - 1]} '
        '${local.day} ${local.year}';
  }
}
