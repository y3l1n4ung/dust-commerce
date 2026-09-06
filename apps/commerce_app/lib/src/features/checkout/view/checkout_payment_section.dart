import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_step_header.dart';

/// Manual provider choice translated from Medusa Payment.
final class CheckoutPaymentSection extends StatelessWidget {
  /// Creates the payment step.
  const CheckoutPaymentSection({
    required this.open,
    required this.state,
    super.key,
  });

  /// Whether payment selection is expanded.
  final bool open;

  /// Retained payment selection and progress.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.isManualPaymentSelected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutStepHeader(
          title: context.tr('shop_checkout_payment', defaultText: 'Payment'),
          open: open,
          complete: selected,
          onEdit: () => context.pushCheckoutStep('payment'),
        ),
        if (open)
          _choice(context, selected)
        else if (selected)
          _summary(context),
        const CheckoutSectionDivider(),
      ],
    );
  }

  Widget _choice(BuildContext context, bool selected) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: StoreColors.base,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: selected ? StoreColors.interactive : StoreColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: state.isBusy
                  ? null
                  : () => context.readCheckoutViewModel().selectManualPayment(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected
                          ? StoreColors.interactive
                          : StoreColors.foregroundMuted,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: TranslatedText(
                        'shop_checkout_manual_payment',
                        defaultText: 'Manual Payment',
                      ),
                    ),
                    const Icon(Icons.credit_card, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed:
                  selected ? () => context.pushCheckoutStep('review') : null,
              child: const TranslatedText(
                'shop_checkout_continue_review',
                defaultText: 'Continue to review',
              ),
            ),
          ),
        ],
      );

  Widget _summary(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PaymentSummary(
              title: context.tr(
                'shop_checkout_payment_method',
                defaultText: 'Payment method',
              ),
              child: const TranslatedText(
                'shop_checkout_manual_payment',
                defaultText: 'Manual Payment',
              ),
            ),
          ),
          Expanded(
            child: _PaymentSummary(
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

final class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.title, required this.child});

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
