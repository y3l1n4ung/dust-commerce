import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Collapsed payment method and next-step details.
final class CheckoutPaymentSummary extends StatelessWidget {
  /// Creates a payment summary.
  const CheckoutPaymentSummary({required this.state, super.key});

  /// Retained payment method.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PaymentSummaryColumn(
              title: context.tr(
                'shop_checkout_payment_method',
                defaultText: 'Payment method',
              ),
              child: state.paymentMethod.match(
                some: (id) => PaymentProviderTitle(id: id),
                none: () => const SizedBox.shrink(),
              ),
            ),
          ),
          Expanded(
            child: _PaymentSummaryColumn(
              title: context.tr(
                'shop_checkout_payment_details',
                defaultText: 'Payment details',
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: TranslatedText(
                      'shop_checkout_payment_next_step',
                      defaultText: 'Another step will appear',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

/// Customer-facing provider title shared by choices and summary.
final class PaymentProviderTitle extends StatelessWidget {
  /// Creates a provider title.
  const PaymentProviderTitle({required this.id, super.key});

  /// Provider identifier from the server.
  final String id;

  @override
  Widget build(BuildContext context) => id == 'manual'
      ? const TranslatedText(
          'shop_checkout_manual_payment',
          defaultText: 'Manual Payment',
        )
      : Text(id);
}

final class _PaymentSummaryColumn extends StatelessWidget {
  const _PaymentSummaryColumn({required this.title, required this.child});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            style: const TextStyle(color: StoreColors.foregroundSubtle),
            child: child,
          ),
        ],
      );
}
